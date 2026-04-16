---
name: skill-usage
description: "스킬 사용 현황 분석. 히팅율, 프로젝트별/세션별 분포, 월별 트렌드 확인.\nTRIGGER when: \"스킬 현황\", \"히팅율\", \"스킬 사용량\", \"어떤 스킬 써?\", 스킬 사용 통계 확인 시.\nSKIP: 스킬 생성/수정은 manage-skills."
argument-hint: "[--project | --sessions | --recent N | --hook-only]"
---

스킬 사용 현황 분석 도구입니다. 대화 기록과 훅 로그를 통합 분석합니다.

## 실행

사용자가 전달한 인자(`$ARGUMENTS`)를 그대로 분석 스크립트에 전달하세요.

```bash
bash scripts/analyze-skill-usage.sh $ARGUMENTS
```

인자가 없으면 전체 요약 모드로 실행합니다.

## 분석 모드

| 인자 | 설명 |
|------|------|
| (없음) | 전체 요약 — 스킬 랭킹, 월별 트렌드, 데이터 소스 |
| `--project` | 프로젝트별 스킬 사용 분포 |
| `--sessions` | 전체 세션 대비 스킬 히팅율 |
| `--recent N` | 최근 N일 데이터만 필터링 |
| `--hook-only` | 훅 로그(실시간 추적)만 분석 |

## 출력 후

분석 결과를 사용자에게 요약해서 전달하세요. 특이점(사용률 0%인 스킬, 급증/급감 트렌드)이 있으면 함께 언급합니다.
