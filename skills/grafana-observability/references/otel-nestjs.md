# NestJS OpenTelemetry 계측

핵심: **OTel SDK를 앱 부트스트랩보다 먼저 시작**해야 한다. 그래야 auto-instrumentation이
HTTP/Express/Nest/DB 모듈을 monkey-patch 할 수 있다. 부트스트랩 이후에 시작하면 이미 로드된
모듈에는 계측이 붙지 않는다.

## 설치

```bash
pnpm add @opentelemetry/sdk-node @opentelemetry/auto-instrumentations-node \
  @opentelemetry/exporter-trace-otlp-proto @opentelemetry/resources \
  @opentelemetry/semantic-conventions @opentelemetry/api
```

## tracing.ts

구 API(`Resource`, `SemanticResourceAttributes`)는 쓰지 않는다. 신 API 사용.

```ts
// src/tracing.ts
import { NodeSDK } from '@opentelemetry/sdk-node';
import { getNodeAutoInstrumentations } from '@opentelemetry/auto-instrumentations-node';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-proto';
import { resourceFromAttributes } from '@opentelemetry/resources';
import { ATTR_SERVICE_NAME } from '@opentelemetry/semantic-conventions';

const sdk = new NodeSDK({
  resource: resourceFromAttributes({ [ATTR_SERVICE_NAME]: 'nest-api' }),
  traceExporter: new OTLPTraceExporter({
    url: 'http://alloy:4318/v1/traces', // 호스트 실행 시 http://localhost:4318/v1/traces
  }),
  instrumentations: [getNodeAutoInstrumentations()],
});

sdk.start();

process.on('SIGTERM', () => {
  sdk.shutdown().finally(() => process.exit(0));
});
```

## 부트스트랩보다 먼저 로드하는 두 가지 방법

**방법 A — main.ts 최상단 import (가장 간단)**: 다른 어떤 import보다 위에 둔다.

```ts
// src/main.ts
import './tracing'; // ⬅️ 반드시 첫 줄. NestFactory보다 먼저 로드되어야 한다
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  await app.listen(3000);
}
bootstrap();
```

**방법 B — `-r` 프리로드 (import 순서 실수 방지)**: 빌드 산출물을 Node로 실행할 때
`--require`로 강제 프리로드한다.

```bash
node -r ./dist/tracing.js dist/main.js
```

```jsonc
// package.json
{
  "scripts": {
    "start:prod": "node -r ./dist/tracing.js dist/main.js"
  }
}
```

시작하면 Nest/Express/HTTP 클라이언트/그리고 지원되는 DB 드라이버(pg, mysql, ioredis 등)에
자동으로 span이 붙는다. 별도 데코레이터 없이 컨트롤러 → 서비스 → DB 호출이 트레이스로 이어진다.

## 커스텀 span 만들기

자동 계측이 안 잡는 비즈니스 로직 구간은 직접 span을 연다.

```ts
// src/orders/orders.service.ts
import { Injectable } from '@nestjs/common';
import { trace, SpanStatusCode } from '@opentelemetry/api';

const tracer = trace.getTracer('orders');

@Injectable()
export class OrdersService {
  async settle(orderId: string) {
    return tracer.startActiveSpan('orders.settle', async (span) => {
      try {
        span.setAttribute('order.id', orderId);
        const result = await this.doSettlement(orderId);
        span.setStatus({ code: SpanStatusCode.OK });
        return result;
      } catch (err) {
        span.recordException(err as Error);
        span.setStatus({ code: SpanStatusCode.ERROR, message: (err as Error).message });
        throw err;
      } finally {
        span.end();
      }
    });
  }

  private async doSettlement(orderId: string) {
    /* ... */
  }
}
```

## 커스텀 메트릭 만들기

메트릭도 내보내려면 SDK에 metric reader를 추가한다.

```ts
// src/tracing.ts 에 추가
import { OTLPMetricExporter } from '@opentelemetry/exporter-metrics-otlp-proto';
import { PeriodicExportingMetricReader } from '@opentelemetry/sdk-metrics';

const sdk = new NodeSDK({
  // ...resource, traceExporter, instrumentations 동일
  metricReader: new PeriodicExportingMetricReader({
    exporter: new OTLPMetricExporter({ url: 'http://alloy:4318/v1/metrics' }),
    exportIntervalMillis: 15_000,
  }),
});
```

```bash
pnpm add @opentelemetry/exporter-metrics-otlp-proto @opentelemetry/sdk-metrics
```

```ts
// 사용처
import { metrics } from '@opentelemetry/api';

const meter = metrics.getMeter('orders');
const orderCounter = meter.createCounter('orders_created_total', {
  description: 'Total orders created',
});

orderCounter.add(1, { channel: 'web' });
```

## 로그 상관관계 (trace_id 주입)

로그에 활성 span의 `trace_id`/`span_id`를 넣으면 Grafana에서 트레이스↔로그를 오갈 수 있다.
nestjs-pino(권장)나 pino의 mixin으로 현재 컨텍스트를 읽어 넣는다.

```bash
pnpm add nestjs-pino pino-http
```

```ts
// src/logger.ts
import { trace, context } from '@opentelemetry/api';

export function traceContextMixin() {
  const span = trace.getSpan(context.active());
  if (!span) return {};
  const { traceId, spanId } = span.spanContext();
  return { trace_id: traceId, span_id: spanId };
}
```

```ts
// src/app.module.ts
import { Module } from '@nestjs/common';
import { LoggerModule } from 'nestjs-pino';
import { traceContextMixin } from './logger';

@Module({
  imports: [
    LoggerModule.forRoot({
      pinoHttp: {
        // 모든 로그 라인에 trace_id/span_id 자동 첨부
        mixin: () => traceContextMixin(),
        // 프로덕션은 JSON, 개발은 pino-pretty
        transport:
          process.env.NODE_ENV !== 'production'
            ? { target: 'pino-pretty' }
            : undefined,
      },
    }),
  ],
})
export class AppModule {}
```

Grafana Loki 데이터소스에서 `trace_id` 필드를 Tempo로 연결하는 derived field 설정은
[dashboards.md](dashboards.md)의 "trace ↔ logs 상호 링크" 참조.

## 트러블슈팅

- **span이 하나도 안 나옴**: `./tracing`이 `NestFactory` import보다 먼저 로드됐는지 확인.
  방법 B(`-r`)가 가장 안전.
- **`Resource is not a constructor` 류 에러**: 구 API를 참조하는 예제다. `resourceFromAttributes` +
  `ATTR_SERVICE_NAME`(신 API)로 교체.
- **연결 거부**: 앱이 컨테이너면 endpoint는 `alloy`, 호스트면 `localhost`.
- **graceful shutdown**: `SIGTERM`에서 `sdk.shutdown()`을 호출해 버퍼된 span을 flush.
