---
name: review-team
description: 7인 토론 기반 리뷰 팀 - 3개 파트(UX, 기술, 리스크)별 2인 토론 후 종합 판정
members:
  - ux-expert
  - ux-researcher
  - tech-architect
  - system-engineer
  - devils-advocate
  - risk-analyst
  - team-reviewer
---

7명의 전문가가 3개 분석 파트에서 2인 토론을 거쳐 깊이 있는 분석을 도출하고, 최종 검토자가 종합 판정을 내리는 리뷰 팀입니다.

## 사용 시점

- 새로운 서비스/기능 기획 검토
- 아키텍처 설계 의사결정
- 대규모 리팩토링 또는 기술 전환 판단
- 중요한 비즈니스 의사결정의 다각도 검증

## 팀 구성

### UX 파트
| 역할 | 에이전트 | 관점 |
|------|---------|------|
| UX 전문가 | `ux-expert` | 경험/직관 기반 사용성, 접근성, 사용자 흐름 |
| UX 리서처 | `ux-researcher` | 데이터/리서치 기반 사용자 연구, 정량적 검증 |

### Tech 파트
| 역할 | 에이전트 | 관점 |
|------|---------|------|
| 기술 아키텍트 | `tech-architect` | 시스템 설계, 확장성, 기술 스택 |
| 시스템 엔지니어 | `system-engineer` | 구현 현실성, 운영, DevOps |

### Risk 파트
| 역할 | 에이전트 | 관점 |
|------|---------|------|
| 비판적 검토자 | `devils-advocate` | 정성적 도전, 가정 검증, 맹점 발견 |
| 리스크 분석가 | `risk-analyst` | 정량적 리스크 평가, 시나리오 모델링 |

### 종합
| 역할 | 에이전트 | 관점 |
|------|---------|------|
| 최종 검토자 | `team-reviewer` | 3개 파트 종합, 충돌 조율, 최종 판정 |

## 워크플로우

```
Phase 1 (3개 파트 병렬 토론 — 각 3라운드)
├── UX 파트
│   ├── Round 1: ux-expert → 초기 분석 제시
│   ├── Round 2: ux-researcher → 데이터 기반 응답/도전
│   └── Round 3: ux-expert → 종합 결론 도출
├── Tech 파트
│   ├── Round 1: tech-architect → 초기 설계 분석
│   ├── Round 2: system-engineer → 구현 관점 검증/도전
│   └── Round 3: tech-architect → 종합 결론 도출
└── Risk 파트
    ├── Round 1: devils-advocate → 초기 리스크 분석
    ├── Round 2: risk-analyst → 정량적 평가/보완
    └── Round 3: devils-advocate → 종합 결론 도출

Phase 2 (종합 판정)
└── team-reviewer: 3개 파트 토론 결과 종합 → 최종 판정
```

각 토론 라운드마다 Slack 알림이 전송되어 실시간으로 진행 상황을 확인할 수 있습니다.

## 호출 방법

```
/review-team [분석 대상 설명]
```

예시:
```
/review-team 새로운 결제 시스템 설계안
/review-team 마이크로서비스 전환 계획
/review-team 소셜 로그인 기능 추가 기획
```
