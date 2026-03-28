---
name: frontend-resume-review
description: 7인 토론 기반 프론트엔드 이력서 검증 팀 - 기술, 프로젝트, 커리어 파트별 2인 토론 후 채용 판정
members:
  - frontend-tech-lead
  - frontend-interviewer
  - project-analyst
  - resume-critic
  - hiring-manager
  - culture-analyst
  - resume-reviewer
---

7명의 전문가가 프론트엔드 개발자 이력서를 3개 관점에서 2인 토론으로 검증하고, 최종 검토자가 채용 판정을 내리는 팀입니다.

## 사용 시점

- 프론트엔드 개발자 이력서 사전 검증
- 면접 전 후보자 분석 및 질문 설계
- 채용 의사결정 지원
- 후보자 비교 분석

## 팀 구성

### 기술 역량 파트
| 역할 | 에이전트 | 관점 |
|------|---------|------|
| 프론트엔드 테크 리드 | `frontend-tech-lead` | 기술 스택 깊이, 아키텍처, 성능, 최신성 |
| 프론트엔드 면접관 | `frontend-interviewer` | 기술 주장 검증, 면접 질문 설계 |

### 프로젝트/성과 파트
| 역할 | 에이전트 | 관점 |
|------|---------|------|
| 프로젝트 분석가 | `project-analyst` | 프로젝트 경험, 기여도, 임팩트 정량화 |
| 이력서 비평가 | `resume-critic` | 과장/불일치 탐지, 신뢰도 평가 |

### 커리어/적합성 파트
| 역할 | 에이전트 | 관점 |
|------|---------|------|
| 채용 매니저 | `hiring-manager` | 커리어 궤적, 성장 잠재력, 시장 가치 |
| 조직적합성 분석가 | `culture-analyst` | 소프트스킬, 협업 스타일, 팀 적합성 |

### 종합
| 역할 | 에이전트 | 관점 |
|------|---------|------|
| 이력서 최종 검토자 | `resume-reviewer` | 3개 파트 종합, 채용 판정, 면접 전략 |

## 워크플로우

```
Phase 1 (3개 파트 병렬 토론 — 각 3라운드)
├── 기술 역량 파트
│   ├── Round 1: frontend-tech-lead → 기술 스택/깊이 초기 평가
│   ├── Round 2: frontend-interviewer → 검증 포인트 식별, 면접 질문 설계
│   └── Round 3: frontend-tech-lead → 종합 기술 역량 결론
├── 프로젝트/성과 파트
│   ├── Round 1: project-analyst → 프로젝트 경험/임팩트 분석
│   ├── Round 2: resume-critic → 과장/불일치 탐지, 신뢰도 도전
│   └── Round 3: project-analyst → 종합 프로젝트 평가 결론
└── 커리어/적합성 파트
    ├── Round 1: hiring-manager → 커리어 궤적/성장 잠재력 분석
    ├── Round 2: culture-analyst → 조직적합성/소프트스킬 도전
    └── Round 3: hiring-manager → 종합 커리어 평가 결론

Phase 2 (종합 판정)
└── resume-reviewer: 3개 파트 결과 종합 → 채용 판정
```

각 토론 라운드마다 Slack 알림이 전송되어 실시간으로 검증 과정을 확인할 수 있습니다.

## 호출 방법

```
/frontend-resume-review [이력서 내용 또는 파일 경로]
```

예시:
```
/frontend-resume-review 김철수_프론트엔드_이력서.pdf
/frontend-resume-review (이력서 내용을 직접 붙여넣기)
```
