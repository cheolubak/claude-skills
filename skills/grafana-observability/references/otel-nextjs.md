# Next.js OpenTelemetry 계측

Next.js는 `instrumentation.ts`의 `register()`를 **서버 프로세스 시작 시 한 번** 호출한다.
여기서 OTel을 등록하면 서버 렌더링/route handler/서버 액션에 자동으로 트레이스가 붙는다.

## 권장: @vercel/otel

```bash
pnpm add @vercel/otel
```

`@vercel/otel`은 SDK 초기화·수출기 구성을 래핑하고 Vercel/self-host 양쪽에서 동작한다.

```ts
// instrumentation.ts (프로젝트 루트, src/ 를 쓰면 src/instrumentation.ts)
import { registerOTel } from '@vercel/otel';

export function register() {
  registerOTel({ serviceName: 'next-web' });
}
```

수출 대상은 표준 OTLP 환경변수로 지정한다. Alloy로 보낸다.

```bash
# .env (혹은 배포 환경변수)
OTEL_EXPORTER_OTLP_ENDPOINT=http://alloy:4318
# 컨테이너 밖 로컬 개발이면
# OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318
OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf
OTEL_SERVICE_NAME=next-web
```

`@vercel/otel`은 기본적으로 HTTP(`/v1/traces`)로 내보낸다. 위 endpoint에 경로를 붙이지 말 것
(`/v1/traces`는 SDK가 자동으로 붙인다).

## next.config — 오래된 버전 대비 (Next 15+ 는 기본 활성)

Next.js 15 이상에서는 `instrumentation.ts`가 안정 기능이라 별도 설정이 필요 없다.
그 이전 버전을 쓴다면:

```ts
// next.config.ts (Next 13~14 에서만 필요)
import type { NextConfig } from 'next';
const nextConfig: NextConfig = {
  experimental: { instrumentationHook: true },
};
export default nextConfig;
```

## 대안: 수동 NodeSDK (세밀한 제어가 필요할 때)

`@vercel/otel` 없이 직접 구성하려면 auto-instrumentation을 붙인 NodeSDK를 등록한다.
**Node 런타임에서만** 실행되도록 가드한다.

```bash
pnpm add @opentelemetry/sdk-node @opentelemetry/auto-instrumentations-node \
  @opentelemetry/exporter-trace-otlp-proto @opentelemetry/resources \
  @opentelemetry/semantic-conventions
```

```ts
// instrumentation.ts
export async function register() {
  // Edge 런타임에서는 Node SDK를 로드하지 않는다
  if (process.env.NEXT_RUNTIME !== 'nodejs') return;
  await import('./instrumentation.node');
}
```

```ts
// instrumentation.node.ts
import { NodeSDK } from '@opentelemetry/sdk-node';
import { getNodeAutoInstrumentations } from '@opentelemetry/auto-instrumentations-node';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-proto';
import { resourceFromAttributes } from '@opentelemetry/resources';
import { ATTR_SERVICE_NAME } from '@opentelemetry/semantic-conventions';

const sdk = new NodeSDK({
  resource: resourceFromAttributes({ [ATTR_SERVICE_NAME]: 'next-web' }),
  traceExporter: new OTLPTraceExporter({
    url: 'http://alloy:4318/v1/traces',
  }),
  instrumentations: [getNodeAutoInstrumentations()],
});
sdk.start();
```

## Web Vitals → 커스텀 메트릭/이벤트

클라이언트 측 실사용자 성능(LCP, INP, CLS 등)은 `useReportWebVitals`로 받아
서버 route로 보내고, 서버에서 OTel 메트릭/로그로 기록한다.

```tsx
// app/_components/web-vitals.tsx
'use client';
import { useReportWebVitals } from 'next/web-vitals';

export function WebVitals() {
  useReportWebVitals((metric) => {
    // sendBeacon으로 언로드 중에도 유실 없이 전송
    const body = JSON.stringify({
      name: metric.name,        // 'LCP' | 'INP' | 'CLS' | 'FCP' | 'TTFB'
      value: metric.value,
      id: metric.id,
      rating: metric.rating,    // 'good' | 'needs-improvement' | 'poor'
      path: window.location.pathname,
    });
    navigator.sendBeacon('/api/vitals', body);
  });
  return null;
}
```

```ts
// app/api/vitals/route.ts
import { metrics } from '@opentelemetry/api';

const meter = metrics.getMeter('web-vitals');
// 히스토그램으로 분포를 남기면 p75/p95 계산이 가능
const histogram = meter.createHistogram('web_vitals', {
  description: 'Core Web Vitals from real users',
});

export async function POST(req: Request) {
  const m = await req.json();
  histogram.record(m.value, { metric: m.name, rating: m.rating, path: m.path });
  return new Response(null, { status: 204 });
}
```

`WebVitals`는 `app/layout.tsx`에서 렌더한다.

```tsx
// app/layout.tsx
import { WebVitals } from './_components/web-vitals';

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="ko">
      <body>
        <WebVitals />
        {children}
      </body>
    </html>
  );
}
```

## 트러블슈팅

- **트레이스가 안 보임**: `instrumentation.ts`가 프로젝트 루트(또는 `src/`)에 있는지,
  export 이름이 정확히 `register`인지 확인. dev 서버 재시작 필요.
- **Edge 런타임 크래시**: `@opentelemetry/sdk-node`는 Node 전용. `NEXT_RUNTIME !== 'nodejs'`
  가드를 넣거나 `@vercel/otel`을 쓴다(edge 안전).
- **endpoint 404**: `OTEL_EXPORTER_OTLP_ENDPOINT`에 `/v1/traces`를 직접 붙이면 이중 경로가 된다.
  base URL만 지정한다.
- **컨테이너에서 `localhost` 연결 실패**: 앱이 컨테이너면 `alloy`(서비스명), 호스트면 `localhost`.
- **개발 중 스팬 과다**: dev에서는 샘플링을 낮추거나(`OTEL_TRACES_SAMPLER=parentbased_traceidratio`,
  `OTEL_TRACES_SAMPLER_ARG=0.1`) 계측을 끈다.
