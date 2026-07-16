# Grafana Alerting (통합 알림) as Code

Grafana의 통합 알림은 alert rule / contact point / notification policy를 모두 파일로 선언할 수 있다.
compose에서 마운트한 `/etc/grafana/provisioning/alerting/` 아래에 YAML을 둔다.

```
grafana/provisioning/alerting/
├── contactpoints.yaml
├── policies.yaml
└── rules.yaml
```

## contactpoints.yaml (Slack 등)

```yaml
apiVersion: 1

contactPoints:
  - orgId: 1
    name: slack-oncall
    receivers:
      - uid: slack-oncall-1
        type: slack
        settings:
          # webhook URL은 파일에 하드코딩하지 말고 환경변수로 주입
          url: ${SLACK_WEBHOOK_URL}
          title: '{{ template "slack.title" . }}'
          text: '{{ template "slack.text" . }}'
        disableResolveMessage: false
```

> `${SLACK_WEBHOOK_URL}`는 Grafana 컨테이너 환경변수로 전달한다(compose `environment:` 또는
> `.env`). 시크릿을 프로비저닝 파일에 커밋하지 않는다.

## policies.yaml (알림 라우팅)

```yaml
apiVersion: 1

policies:
  - orgId: 1
    receiver: slack-oncall       # 기본 수신처
    group_by: ['alertname', 'service']
    group_wait: 30s
    group_interval: 5m
    repeat_interval: 4h
    routes:
      - receiver: slack-oncall
        matchers:
          - severity = critical
        group_wait: 10s
        repeat_interval: 1h
```

## rules.yaml (알림 규칙)

규칙은 데이터소스 쿼리(PromQL) → 임계값 조건 → 알림으로 구성된다. `datasourceUid`는
[dashboards.md](dashboards.md)에서 선언한 uid(`prometheus`)를 쓴다.

```yaml
apiVersion: 1

groups:
  - orgId: 1
    name: app-red
    folder: Alerts
    interval: 1m
    rules:
      - uid: high-error-rate
        title: High 5xx error rate
        condition: C
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: '{{ $labels.service_name }} 5xx 비율이 5%를 초과'
          runbook_url: https://wiki.example.com/runbooks/high-error-rate
        data:
          - refId: A
            relativeTimeRange: { from: 600, to: 0 }
            datasourceUid: prometheus
            model:
              expr: |
                sum(rate(http_server_request_duration_seconds_count{http_response_status_code=~"5.."}[5m])) by (service_name)
                /
                sum(rate(http_server_request_duration_seconds_count[5m])) by (service_name)
              instant: true
              refId: A
          - refId: C
            datasourceUid: __expr__
            model:
              type: threshold
              expression: A
              conditions:
                - evaluator: { type: gt, params: [0.05] }  # 5%
              refId: C
```

## SLO 에러버짓 번레이트 알림 (멀티윈도우)

가용성 SLO(예: 99.9%)의 에러버짓 소진 속도(burn rate)로 알림한다. 짧은 창(급성)과 긴 창(만성)을
함께 봐 오탐을 줄이는 것이 표준 패턴이다. 아래는 "5분 & 1시간 창에서 동시에 14.4배 초과"
(=하루 만에 30일치 버짓 소진 속도) 조건.

```yaml
groups:
  - orgId: 1
    name: slo-burn-rate
    folder: Alerts
    interval: 1m
    rules:
      - uid: slo-fast-burn
        title: SLO fast burn (2% budget in 1h)
        condition: C
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: 에러버짓 급속 소진 — 14.4x burn rate (5m & 1h)
        data:
          # 5분 창 burn rate
          - refId: short
            relativeTimeRange: { from: 300, to: 0 }
            datasourceUid: prometheus
            model:
              refId: short
              instant: true
              expr: |
                sum(rate(http_server_request_duration_seconds_count{http_response_status_code=~"5.."}[5m]))
                /
                sum(rate(http_server_request_duration_seconds_count[5m]))
          # 1시간 창 burn rate
          - refId: long
            relativeTimeRange: { from: 3600, to: 0 }
            datasourceUid: prometheus
            model:
              refId: long
              instant: true
              expr: |
                sum(rate(http_server_request_duration_seconds_count{http_response_status_code=~"5.."}[1h]))
                /
                sum(rate(http_server_request_duration_seconds_count[1h]))
          # 두 창 모두 임계 burn rate(14.4x * (1 - 0.999) = 0.0144) 초과
          - refId: C
            datasourceUid: __expr__
            model:
              type: math
              # 둘 다 초과할 때만 발화
              expression: '$short > 0.0144 && $long > 0.0144'
              refId: C
```

번레이트 임계값 계산 근거:

| 버짓 소진 속도 | burn rate | 권장 창(short/long) | severity |
|---|---|---|---|
| 1시간에 2% | 14.4x | 5m / 1h | critical (페이지) |
| 6시간에 5% | 6x | 30m / 6h | critical |
| 3일에 10% | 1x | 6h / 3d | warning (티켓) |

임계값 = `burn_rate * (1 - SLO목표)`. SLO 99.9%면 `1 - 0.999 = 0.001`, 14.4x면 `0.0144`.

## 적용 & 확인

```bash
# 프로비저닝 파일 반영(컨테이너 재기동 또는 리로드)
docker compose restart grafana

# UI: Alerting → Alert rules 에서 규칙이 'Provisioned'로 뜨는지 확인
```

> 프로비저닝된 규칙은 UI에서 편집 불가(파일이 소스 오브 트루스). 변경은 YAML을 고치고 커밋한다.
> contact point 테스트는 Alerting → Contact points → Test로 Slack 수신을 먼저 검증한다.
