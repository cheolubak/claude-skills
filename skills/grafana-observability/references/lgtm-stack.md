# LGTM 스택 — docker-compose 수집 구성

앱은 OTLP로 **Alloy 한 곳**에만 내보내고, Alloy가 Loki/Tempo/Prometheus로 팬아웃한다.
아래 파일들을 프로젝트 루트의 `observability/` 디렉토리에 그대로 두고 `docker compose up -d`.

```
observability/
├── docker-compose.yml
├── config.alloy
├── loki-config.yaml
├── tempo.yaml
├── prometheus.yml
└── grafana/
    └── provisioning/          # 상세는 dashboards.md 참조
        ├── datasources/
        └── dashboards/
```

## docker-compose.yml

```yaml
services:
  grafana:
    image: grafana/grafana:11.5.0
    ports:
      - "3000:3000"
    environment:
      GF_SECURITY_ADMIN_USER: admin
      GF_SECURITY_ADMIN_PASSWORD: admin
      # Tempo → Loki/Prometheus 상호 링크에 필요한 기능 플래그
      GF_FEATURE_TOGGLES_ENABLE: traceqlEditor
    volumes:
      - ./grafana/provisioning:/etc/grafana/provisioning
      - grafana-data:/var/lib/grafana
    depends_on:
      - loki
      - tempo
      - prometheus

  alloy:
    image: grafana/alloy:v1.6.1
    command:
      - run
      - /etc/alloy/config.alloy
      - --server.http.listen-addr=0.0.0.0:12345
      - --storage.path=/var/lib/alloy/data
    ports:
      - "4317:4317"   # OTLP gRPC
      - "4318:4318"   # OTLP HTTP
      - "12345:12345" # Alloy UI (디버깅)
    volumes:
      - ./config.alloy:/etc/alloy/config.alloy
      - alloy-data:/var/lib/alloy/data
    depends_on:
      - loki
      - tempo
      - prometheus

  loki:
    image: grafana/loki:3.3.2
    command: -config.file=/etc/loki/loki-config.yaml
    ports:
      - "3100:3100"
    volumes:
      - ./loki-config.yaml:/etc/loki/loki-config.yaml
      - loki-data:/loki

  tempo:
    image: grafana/tempo:2.7.0
    command: -config.file=/etc/tempo/tempo.yaml
    ports:
      - "3200:3200"   # Tempo API (Grafana 데이터소스용)
    volumes:
      - ./tempo.yaml:/etc/tempo/tempo.yaml
      - tempo-data:/var/tempo

  prometheus:
    image: prom/prometheus:v3.1.0
    command:
      - --config.file=/etc/prometheus/prometheus.yml
      # remote_write 수신을 켜야 Alloy가 메트릭을 push 할 수 있다
      - --web.enable-remote-write-receiver
      - --enable-feature=exemplar-storage
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus-data:/prometheus

volumes:
  grafana-data:
  alloy-data:
  loki-data:
  tempo-data:
  prometheus-data:
```

## config.alloy (River 문법)

Alloy는 OpenTelemetry Collector 배포판이다. OTLP를 수신해 batch 처리 후 신호별로 내보낸다.

```alloy
otelcol.receiver.otlp "default" {
  grpc { endpoint = "0.0.0.0:4317" }
  http { endpoint = "0.0.0.0:4318" }
  output {
    metrics = [otelcol.processor.batch.default.input]
    logs    = [otelcol.processor.batch.default.input]
    traces  = [otelcol.processor.batch.default.input]
  }
}

otelcol.processor.batch "default" {
  output {
    metrics = [otelcol.exporter.prometheus.default.input]
    logs    = [otelcol.exporter.loki.default.input]
    traces  = [otelcol.exporter.otlp.tempo.input]
  }
}

// 메트릭 → Prometheus (remote_write)
otelcol.exporter.prometheus "default" {
  forward_to = [prometheus.remote_write.default.receiver]
}
prometheus.remote_write "default" {
  endpoint { url = "http://prometheus:9090/api/v1/write" }
}

// 로그 → Loki
otelcol.exporter.loki "default" {
  forward_to = [loki.write.default.receiver]
}
loki.write "default" {
  endpoint { url = "http://loki:3100/loki/api/v1/push" }
}

// 트레이스 → Tempo (OTLP)
otelcol.exporter.otlp "tempo" {
  client {
    endpoint = "tempo:4317"
    tls { insecure = true }
  }
}
```

> `prometheus.remote_write`가 동작하려면 Prometheus를 `--web.enable-remote-write-receiver`로
> 실행해야 한다(위 compose에 반영됨). 안 켜면 `404 /api/v1/write` 에러가 난다.

## loki-config.yaml (최소 단일 노드)

```yaml
auth_enabled: false

server:
  http_listen_port: 3100

common:
  instance_addr: 127.0.0.1
  path_prefix: /loki
  storage:
    filesystem:
      chunks_directory: /loki/chunks
      rules_directory: /loki/rules
  replication_factor: 1
  ring:
    kvstore:
      store: inmemory

schema_config:
  configs:
    - from: 2024-01-01
      store: tsdb
      object_store: filesystem
      schema: v13
      index:
        prefix: index_
        period: 24h

limits_config:
  # OTLP push에서 리소스 속성이 인덱스 라벨로 승격되도록 허용
  allow_structured_metadata: true
  volume_enabled: true
```

## tempo.yaml (최소 단일 노드)

```yaml
server:
  http_listen_port: 3200

distributor:
  receivers:
    otlp:
      protocols:
        grpc:
          endpoint: "0.0.0.0:4317"
        http:
          endpoint: "0.0.0.0:4318"

storage:
  trace:
    backend: local
    local:
      path: /var/tempo/blocks
    wal:
      path: /var/tempo/wal

# service graph / span metrics를 Prometheus로 내보내려면 metrics_generator 활성화
metrics_generator:
  registry:
    external_labels:
      source: tempo
  storage:
    path: /var/tempo/generator/wal
    remote_write:
      - url: http://prometheus:9090/api/v1/write
        send_exemplars: true

overrides:
  defaults:
    metrics_generator:
      processors: [service-graphs, span-metrics]
```

> Tempo는 OTLP 4317/4318을 자체적으로도 수신할 수 있지만, 위 구성에서는 **모든 앱 트래픽을 Alloy로
> 통일**하고 Alloy가 Tempo(`tempo:4317`)로 넘긴다. 포트 충돌을 피하려 Tempo의 4317/4318은 호스트로
> 노출하지 않았다.

## prometheus.yml

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  # Prometheus 자기 자신
  - job_name: prometheus
    static_configs:
      - targets: ["localhost:9090"]

  # Alloy 자체 메트릭(선택)
  - job_name: alloy
    static_configs:
      - targets: ["alloy:12345"]
```

> 앱 메트릭은 scrape가 아니라 **Alloy → remote_write(push)** 로 들어온다. 그래서 여기엔
> 앱 target을 적지 않는다. pull 방식이 필요하면 `otelcol.exporter.prometheus`를
> `prometheus.exporter`/scrape로 바꾸면 된다.

## 실행 & 확인

```bash
docker compose up -d
docker compose ps

# OTLP 수신 확인 (앱 대신 수동 테스트)
curl -v http://localhost:4318/v1/traces -H 'Content-Type: application/json' -d '{}'
```

- Grafana: `http://localhost:3000` (admin/admin)
- 데이터소스(Loki/Tempo/Prometheus) 자동 프로비저닝은 [dashboards.md](dashboards.md) 참조.
- 앱에서는 `OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318`(호스트) 또는
  `http://alloy:4318`(같은 compose 네트워크 내)로 지정.
