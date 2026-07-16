# Grafana 데이터소스 · 대시보드 프로비저닝 (as Code)

Grafana UI에서 클릭으로 만든 데이터소스/대시보드는 재현이 안 된다. 전부 파일로 선언하고 Git에 넣어
컨테이너 기동 시 자동 적용되게 한다. compose에서 `./grafana/provisioning`을
`/etc/grafana/provisioning`으로 마운트한다([lgtm-stack.md](lgtm-stack.md) 참조).

```
grafana/provisioning/
├── datasources/
│   └── datasources.yaml
└── dashboards/
    ├── dashboards.yaml         # provider (JSON 파일을 어디서 읽을지)
    └── json/
        └── app-overview.json   # 대시보드 정의(Git 관리)
```

## datasources/datasources.yaml

Loki/Tempo/Prometheus 세 데이터소스를 선언하고, **서로를 연결**한다(핵심).

```yaml
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    uid: prometheus
    url: http://prometheus:9090
    isDefault: true
    jsonData:
      httpMethod: POST
      exemplarTraceIdDestinations:
        # 메트릭 exemplar → 트레이스로 점프
        - name: trace_id
          datasourceUid: tempo

  - name: Loki
    type: loki
    access: proxy
    uid: loki
    url: http://loki:3100
    jsonData:
      derivedFields:
        # 로그의 trace_id 필드 → Tempo 트레이스로 링크
        - name: trace_id
          matcherType: label
          matcherRegex: trace_id
          url: "$${__value.raw}"
          datasourceUid: tempo

  - name: Tempo
    type: tempo
    access: proxy
    uid: tempo
    url: http://tempo:3200
    jsonData:
      # 트레이스 → 관련 로그(Loki)로 점프
      tracesToLogsV2:
        datasourceUid: loki
        spanStartTimeShift: -5m
        spanEndTimeShift: 5m
        filterByTraceID: true
        tags:
          - key: service.name
            value: service_name
      # 트레이스 → 관련 메트릭(Prometheus)
      tracesToMetrics:
        datasourceUid: prometheus
        spanStartTimeShift: -5m
        spanEndTimeShift: 5m
      # service graph(span metrics)
      serviceMap:
        datasourceUid: prometheus
      nodeGraph:
        enabled: true
```

> `$$`는 compose 변수 확장을 피하기 위한 이스케이프다. Grafana에는 `${__value.raw}`로 전달된다.

## trace ↔ logs ↔ metrics 상호 링크 (동작 확인)

세 데이터소스가 위처럼 연결되면 Grafana Explore에서:

- **로그 → 트레이스**: Loki 로그 라인에 `trace_id` 필드가 있으면 "Tempo" 링크가 뜬다.
  ([otel-nestjs.md](otel-nestjs.md)의 로그 상관관계로 `trace_id`를 심는다.)
- **트레이스 → 로그**: Tempo 트레이스 span에서 "Logs for this span" → 같은 시간대 Loki 로그.
- **메트릭 → 트레이스**: PromQL 그래프의 exemplar 점(다이아몬드)을 클릭하면 해당 트레이스로 점프.

## dashboards/dashboards.yaml (provider)

```yaml
apiVersion: 1

providers:
  - name: 'app-dashboards'
    orgId: 1
    folder: 'Applications'
    type: file
    disableDeletion: false
    updateIntervalSeconds: 30   # 파일 변경 자동 반영
    allowUiUpdates: true
    options:
      path: /etc/grafana/provisioning/dashboards/json
      foldersFromFilesStructure: true
```

## dashboards/json/app-overview.json (예: 골든 시그널)

대시보드 JSON은 통째로 Git에서 관리한다. 아래는 RED(요청률·에러율·지연) 요약 패널의 축약 예.

```json
{
  "title": "App Overview (RED)",
  "uid": "app-overview",
  "tags": ["app", "red"],
  "timezone": "browser",
  "schemaVersion": 39,
  "refresh": "30s",
  "templating": {
    "list": [
      {
        "name": "service",
        "type": "query",
        "datasource": { "type": "prometheus", "uid": "prometheus" },
        "query": "label_values(http_server_request_duration_seconds_count, service_name)",
        "refresh": 2
      }
    ]
  },
  "panels": [
    {
      "title": "Request rate (req/s)",
      "type": "timeseries",
      "datasource": { "type": "prometheus", "uid": "prometheus" },
      "gridPos": { "h": 8, "w": 12, "x": 0, "y": 0 },
      "targets": [
        {
          "expr": "sum(rate(http_server_request_duration_seconds_count{service_name=\"$service\"}[5m]))",
          "legendFormat": "req/s"
        }
      ]
    },
    {
      "title": "Error rate (5xx %)",
      "type": "timeseries",
      "datasource": { "type": "prometheus", "uid": "prometheus" },
      "gridPos": { "h": 8, "w": 12, "x": 12, "y": 0 },
      "targets": [
        {
          "expr": "sum(rate(http_server_request_duration_seconds_count{service_name=\"$service\",http_response_status_code=~\"5..\"}[5m])) / sum(rate(http_server_request_duration_seconds_count{service_name=\"$service\"}[5m]))",
          "legendFormat": "error ratio"
        }
      ]
    },
    {
      "title": "Latency p95 (s)",
      "type": "timeseries",
      "datasource": { "type": "prometheus", "uid": "prometheus" },
      "gridPos": { "h": 8, "w": 24, "x": 0, "y": 8 },
      "targets": [
        {
          "expr": "histogram_quantile(0.95, sum(rate(http_server_request_duration_seconds_bucket{service_name=\"$service\"}[5m])) by (le))",
          "legendFormat": "p95"
        }
      ]
    }
  ]
}
```

> 메트릭 이름(`http_server_request_duration_seconds_*`)은 OTel semantic conventions를 따른다.
> Alloy가 OTLP를 Prometheus로 변환하면서 dot을 underscore로 바꾼다
> (`http.server.request.duration` → `http_server_request_duration_seconds`).

## Git 워크플로

1. Grafana UI에서 대시보드를 만들거나 수정한다.
2. 대시보드 → Share → **Export → Save to file**(또는 JSON Model 복사)로 JSON을 얻는다.
3. `grafana/provisioning/dashboards/json/*.json`에 저장하고 커밋한다.
4. `updateIntervalSeconds` 주기로 Grafana가 파일을 다시 읽어 반영(재기동 불필요).

> 프로비저닝된 대시보드는 UI에서 편집해도 파일이 소스 오브 트루스다. `allowUiUpdates: true`면
> UI 편집을 허용하되, 최종본은 반드시 파일로 export해 커밋해야 유실되지 않는다.
