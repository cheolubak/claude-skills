---
name: grafana-observability
description: "Grafana LGTM 관측성 스택. Loki(로그)·Tempo(트레이스)·Prometheus/Mimir(메트릭)·Grafana·Alloy 수집, Next.js/NestJS OpenTelemetry 계측, 대시보드/알림 as Code.\nTRIGGER when: \"모니터링 설정\", \"관측성\", \"Grafana\", \"OpenTelemetry\", \"OTel\", \"트레이싱\", \"로그 수집\", \"메트릭\", \"Loki\", \"Tempo\", \"Prometheus\", \"대시보드 구성\", \"알림 설정\", 앱 관측성/모니터링 구축 시.\nSKIP: 에러 추적(Sentry) 기본 설정과 헬스체크 엔드포인트만이면 nextjs-deployment."
---

# Grafana LGTM 관측성 가이드

> 참조:
> - [references/lgtm-stack.md](references/lgtm-stack.md) - docker-compose로 Loki/Tempo/Prometheus/Grafana + Alloy 수집 구성
> - [references/otel-nextjs.md](references/otel-nextjs.md) - Next.js instrumentation.ts, @vercel/otel, Web Vitals
> - [references/otel-nestjs.md](references/otel-nestjs.md) - NestJS OTel SDK, bootstrap 전 초기화, 자동 계측
> - [references/dashboards.md](references/dashboards.md) - 데이터소스/대시보드 프로비저닝(as Code)
> - [references/alerting.md](references/alerting.md) - Grafana Alerting 규칙, contact points, SLO 번레이트

## 한눈에 보는 데이터 흐름

애플리케이션(Next.js / NestJS)이 OTLP로 텔레메트리를 내보내면, Grafana Alloy가 이를 수신해
신호별로 백엔드에 라우팅하고, Grafana가 세 백엔드를 하나의 화면에서 조회한다.

```
                                          ┌─────────────────────┐
  ┌──────────────┐                        │  Prometheus (메트릭)  │─┐
  │ Next.js /    │   OTLP (gRPC 4317 /    │  Loki       (로그)   │ │   ┌──────────┐
  │ NestJS 앱    │──── HTTP 4318) ───────▶│  Grafana Alloy       │─┤──▶│ Grafana  │
  │ (OTel SDK)   │   metrics/logs/traces  │  (OTel Collector)    │ │   │ (조회 UI) │
  └──────────────┘                        │  Tempo      (트레이스)│─┘   └──────────┘
                                          └─────────────────────┘
```

- **L**oki: 로그 저장/조회 (LogQL)
- **G**rafana: 통합 대시보드 + Alerting
- **T**empo: 분산 트레이스 저장/조회 (TraceQL), 로그·메트릭과 상호 링크
- **M**imir(또는 Prometheus): 메트릭 저장/조회 (PromQL)
- **Alloy**: OTel Collector 배포판. OTLP 단일 수신 후 3개 백엔드로 팬아웃
  (구 Promtail·Grafana Agent는 deprecated, Alloy로 대체됨).

## 가장 자주 쓰는 시작점

1. **스택 먼저 띄우기**: [lgtm-stack.md](references/lgtm-stack.md)의 `docker-compose.yml` + config 파일을
   그대로 복사해 `docker compose up -d`. Grafana는 `http://localhost:3000` (admin/admin).
2. **앱 계측**: 프론트는 [otel-nextjs.md](references/otel-nextjs.md), 백엔드는 [otel-nestjs.md](references/otel-nestjs.md).
   공통 환경변수 `OTEL_EXPORTER_OTLP_ENDPOINT=http://alloy:4318` (컨테이너 밖이면 `http://localhost:4318`).
3. **대시보드/알림을 Git으로 관리**: [dashboards.md](references/dashboards.md), [alerting.md](references/alerting.md).

> 핵심 원칙: 앱은 백엔드를 몰라도 된다. 앱은 **Alloy(OTLP) 한 곳으로만** 내보내고,
> 라우팅·백엔드 교체는 Alloy config에서만 바꾼다.
