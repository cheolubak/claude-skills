# Claude Code Skills & Agents

Claude Code에서 사용할 수 있는 커스텀 스킬(Skills), 에이전트(Agents), 팀(Teams) 모음입니다.

## Setting

```bash
# setting agents
$ ln -s $(pwd)/agents $HOME/.claude/agents

# setting skills
$ ln -s $(pwd)/skills $HOME/.claude/skills

# setting teams
$ ln -s $(pwd)/teams $HOME/.claude/teams

# setting rules
$ ln -s $(pwd)/rules $HOME/.claude/rules

# setting hooks
$ ln -s $(pwd)/hooks $HOME/.claude/hooks

# setting settings.json
$ ln -s $(pwd)/settings.json $HOME/.claude/settings.json

# setting notify.sh
$ ln -s $(pwd)/notify.sh $HOME/.claude/notify.sh

# setting statusline.sh
$ ln -s $(pwd)/statusline.sh $HOME/.claude/statusline.sh
```

## 프로젝트 구조

```
claude-skills/
├── agents/
│   ├── code-simplifier.md
│   ├── culture-analyst.md
│   ├── devils-advocate.md
│   ├── frontend-interviewer.md
│   ├── frontend-tech-lead.md
│   ├── hiring-manager.md
│   ├── nestjs-reviewer.md
│   ├── nextjs-reviewer.md
│   ├── project-analyst.md
│   ├── resume-critic.md
│   ├── resume-reviewer.md
│   ├── risk-analyst.md
│   ├── system-engineer.md
│   ├── team-reviewer.md
│   ├── tech-architect.md
│   ├── ux-expert.md
│   └── ux-researcher.md
├── hooks/
│   ├── commit-session.sh
│   ├── load-recent-changes.sh
│   ├── run-review-part.sh
│   ├── run-review-synthesis.sh
│   ├── slack-agent-message.sh
│   ├── slack-agent-progress.sh
│   ├── slack-team-notify.sh
│   ├── slack-team-progress.sh
│   └── stop-notify.sh
├── rules/
│   ├── agents.md
│   ├── skills.md
│   └── teams.md
├── skills/
│   ├── cache-components/
│   ├── diff-commit/
│   ├── framer-motion/
│   ├── frontend-resume-review/
│   ├── manage-skills/
│   ├── merge-worktree/
│   ├── nestjs-auth/
│   ├── nestjs-config/
│   ├── nestjs-crud/
│   ├── nestjs-database/
│   ├── nestjs-error-handling/
│   ├── nestjs-monorepo/
│   ├── nestjs-semantic-search/
│   ├── nestjs-swagger/
│   ├── nestjs-testing/
│   ├── nestjs-validation/
│   ├── nextjs-a11y/
│   ├── nextjs-auth/
│   ├── nextjs-deployment/
│   ├── nextjs-i18n/
│   ├── nextjs-monorepo/
│   ├── nextjs-seo/
│   ├── nextjs-shadcn/
│   ├── nextjs-testing/
│   ├── react-best-practices/
│   ├── react-hook-form/
│   ├── request-pr/
│   ├── review-team/
│   ├── server-actions/
│   ├── tailwind-patterns/
│   ├── tanstack-query/
│   ├── typescript-patterns/
│   ├── verify-implementation/
│   └── zustand-patterns/
├── teams/
│   ├── frontend-resume-review.md
│   └── review-team.md
├── CLAUDE.md
├── notify.sh
├── settings.json
├── statusline.sh
└── work-log.md
```

## Agents

### Service / Code Review

| 에이전트 | 설명 |
|---------|------|
| **code-simplifier** | 모든 기능을 보존하면서 코드의 명확성, 일관성, 유지보수성을 높이도록 단순화하고 개선합니다. |
| **nextjs-reviewer** | Next.js + pnpm 애플리케이션을 확립된 패턴에 따라 리뷰합니다. 심각한 이슈는 자동 수정하고 권장사항을 보고합니다. |
| **nestjs-reviewer** | NestJS 애플리케이션을 확립된 패턴에 따라 리뷰합니다. 심각한 이슈는 자동 수정하고 권장사항을 보고합니다. |
| **ux-expert** | UX 전문가 - 사용자 경험, 사용성, 접근성, 사용자 흐름을 분석하고 개선안을 제시합니다. |
| **ux-researcher** | UX 리서처 - 데이터 기반 사용자 연구, 정량적 사용성 분석, 경쟁 벤치마크로 UX 의사결정을 검증합니다. |
| **tech-architect** | 기술 아키텍트 - 시스템 설계, 확장성, 성능, 기술 스택 선택을 분석하고 아키텍처 의사결정을 기록합니다. |
| **system-engineer** | 시스템 엔지니어 - 구현 가능성, 운영 현실성, DevOps 관점에서 아키텍처 설계를 검증합니다. |
| **devils-advocate** | 비판적 검토자 - 가정을 도전하고, 위험을 탐색하며, 맹점을 발견하여 의사결정의 질을 높입니다. |
| **risk-analyst** | 리스크 분석가 - 정량적 리스크 평가, 시나리오 모델링, 구조화된 완화 전략을 제시합니다. |
| **team-reviewer** | 최종 검토자 - 모든 관점(UX, 기술, 리스크)을 종합하여 충돌을 조율하고 실행 가능한 결론을 도출합니다. |

### Resume Review

| 에이전트 | 설명 |
|---------|------|
| **frontend-tech-lead** | 프론트엔드 테크 리드 - 이력서의 기술 스택 깊이, 아키텍처 이해도, 최신 기술 동향 파악 수준을 평가합니다. |
| **frontend-interviewer** | 프론트엔드 면접관 - 이력서 기술 주장의 검증 포인트를 식별하고 맞춤형 면접 질문을 설계합니다. |
| **project-analyst** | 프로젝트 분석가 - 이력서의 프로젝트 경험, 기여도, 임팩트를 분석하고 실질적 역량을 평가합니다. |
| **resume-critic** | 이력서 비평가 - 과장, 불일치, 공백을 탐지하고 이력서의 신뢰도를 평가합니다. |
| **hiring-manager** | 채용 매니저 - 커리어 궤적, 성장 잠재력, 연차 대비 역량 수준을 평가합니다. |
| **culture-analyst** | 조직적합성 분석가 - 소프트스킬, 커뮤니케이션 스타일, 팀 기여 신호를 분석합니다. |
| **resume-reviewer** | 이력서 최종 검토자 - 기술, 프로젝트, 커리어 분석을 종합하여 채용 판정을 내립니다. |

## Teams

| 팀 | 멤버 | 설명 |
|----|------|------|
| **review-team** | ux-expert, ux-researcher, tech-architect, system-engineer, devils-advocate, risk-analyst, team-reviewer | 7인 토론 기반 리뷰 팀. 3개 파트(UX, 기술, 리스크)별 2인 토론 후 종합 판정을 도출합니다. |
| **frontend-resume-review** | frontend-tech-lead, frontend-interviewer, project-analyst, resume-critic, hiring-manager, culture-analyst, resume-reviewer | 7인 토론 기반 프론트엔드 이력서 검증 팀. 기술, 프로젝트, 커리어 파트별 2인 토론 후 채용 판정을 내립니다. |

사용법:
- `/review-team [분석 대상]`
- `/frontend-resume-review [이력서 파일]`

## Skills

### NestJS

| 스킬 | 설명 |
|------|------|
| **nestjs-auth** | 인증/인가 설정 (JWT, Guard, 로그인, OAuth) |
| **nestjs-config** | 환경설정 관리 (.env, ConfigModule) |
| **nestjs-crud** | CRUD 모듈 스캐폴딩 (리소스 생성, 페이지네이션) |
| **nestjs-database** | 데이터베이스 패턴 (TypeORM, Prisma, 마이그레이션) |
| **nestjs-error-handling** | 예외 처리 (Exception Filter, 커스텀 예외) |
| **nestjs-monorepo** | 모노레포 설정 (Turborepo, pnpm workspaces, 공유 라이브러리, 배포) |
| **nestjs-semantic-search** | 시맨틱 검색 (pgvector, 임베딩, RAG) |
| **nestjs-swagger** | Swagger/OpenAPI 문서화 |
| **nestjs-testing** | 테스트 작성 (유닛 테스트, E2E 테스트) |
| **nestjs-validation** | DTO 유효성 검증 (class-validator) |

### Next.js

| 스킬 | 설명 |
|------|------|
| **cache-components** | Cache Components (`use cache`) 패턴 (cacheTag, cacheLife) |
| **nextjs-a11y** | 웹 접근성 (WCAG 2.2, ARIA, 키보드 네비게이션) |
| **nextjs-auth** | 인증/인가 패턴 (Auth.js v5, 미들웨어 보호, 세션 관리, RBAC) |
| **nextjs-deployment** | 배포 패턴 (Docker standalone, Vercel, GitHub Actions CI/CD, 모니터링) |
| **nextjs-i18n** | 다국어 지원 (i18next, react-i18next, 번역 키 관리) |
| **nextjs-monorepo** | 모노레포 설정 (Turborepo, pnpm workspaces, 공유 패키지, 배포) |
| **nextjs-seo** | SEO 최적화 (Metadata API, 사이트맵, JSON-LD) |
| **nextjs-shadcn** | shadcn/ui 컴포넌트 패턴 |
| **nextjs-testing** | 테스트 (Vitest 유닛 테스트, Cypress 컴포넌트/E2E 테스트) |
| **server-actions** | Server Actions 패턴 (Zod 유효성 검사, 에러 처리) |

### React / UI

| 스킬 | 설명 |
|------|------|
| **react-best-practices** | React + Next.js 모범 사례 (상태 관리, 성능 최적화) |
| **react-hook-form** | React Hook Form + Zod 심화 폼 패턴 (멀티스텝 폼, 동적 필드, Server Action 연동) |
| **framer-motion** | Motion (Framer Motion) v11+ 애니메이션 패턴 (레이아웃, 페이지 전환, 스크롤, 제스처) |
| **tailwind-patterns** | Tailwind CSS 패턴 (테마 시스템, 다크모드, 애니메이션) |
| **tanstack-query** | TanStack Query v5 데이터 페칭 (프리페칭, 옵티미스틱 업데이트, 무한 스크롤) |
| **typescript-patterns** | React/Next.js TypeScript 고급 패턴 (제네릭, Zod 타입 추론, 유틸리티 타입) |
| **zustand-patterns** | Zustand 상태 관리 패턴 (스토어 설계, 슬라이스, persist/immer 미들웨어) |

### Utility

| 스킬 | 설명 |
|------|------|
| **diff-commit** | 현재 변경사항을 분석하여 논리적 작업 단위별로 분리된 커밋 자동 생성 |
| **manage-skills** | 세션 변경사항을 분석하여 스킬 누락을 탐지하고, 새 스킬 생성 또는 기존 스킬 업데이트 |
| **merge-worktree** | 현재 worktree 브랜치를 메인 브랜치에 머지 (하나의 작업이면 squash, 독립적 커밋이면 rebase) |
| **request-pr** | 커밋 히스토리를 분석하여 지정 브랜치로 GitHub PR 생성 (한글) |
| **review-team** | 7인 토론 기반 리뷰 팀으로 서비스/기능을 다각도 분석 |
| **frontend-resume-review** | 7인 토론 기반 프론트엔드 이력서 검증 팀으로 이력서를 다각도 분석 |
| **verify-implementation** | 프로젝트의 모든 verify 스킬을 순차 실행하여 통합 검증 보고서 생성 |

## Hooks

### Shell Scripts (`hooks/`)

| 훅 | 트리거 | 설명 |
|----|--------|------|
| **commit-session.sh** | Stop | 세션 종료 시 변경사항을 자동 커밋 (Claude headless 모드로 커밋 메시지 생성) |
| **load-recent-changes.sh** | SessionStart | 세션 시작 시 최근 CHANGELOG 엔트리와 git log를 컨텍스트로 로드 |
| **run-review-part.sh** | 수동 | 3라운드 토론을 독립 세션으로 실행하고 Slack 스레드로 결과를 전달 |
| **run-review-synthesis.sh** | 수동 | 3개 파트의 최종 결론을 종합하여 최종 판정을 내리고 저장 |
| **slack-agent-message.sh** | PostToolUse | SendMessage/Agent 도구의 에이전트 응답을 실시간으로 Slack에 자동 전송 |
| **slack-agent-progress.sh** | PreToolUse | SendMessage/Agent 도구 실행 전 "요청 중" 상태를 Slack에 미리 알림 |
| **slack-team-notify.sh** | 수동 | 팀별 Slack 채널로 에이전트 분석 내용을 메시지로 전송 (스레드 지원) |
| **slack-team-progress.sh** | 수동 | 팀 워크플로우의 시작/진행/완료/전체완료 단계별 진행 상황을 Slack에 알림 |
| **stop-notify.sh** | Stop | 세션 종료 시 작업 요약과 git 컨텍스트를 Slack으로 전달 |

### Inline Hooks (`settings.json`)

| 트리거 | 매처 | 설명 |
|--------|------|------|
| **SessionStart** | 전체 | `load-recent-changes.sh` 실행하여 최근 변경사항 로드 |
| **PreToolUse** | Bash | 위험 명령 차단 (`rm -rf /`, `git push --force`, `DROP TABLE` 등 감지 시 실행 중단) |
| **PreToolUse** | SendMessage | `slack-agent-progress.sh` 실행하여 에이전트 요청 상태 Slack 알림 |
| **PreToolUse** | Agent | `slack-agent-progress.sh` 실행하여 에이전트 요청 상태 Slack 알림 |
| **PostToolUse** | SendMessage | `slack-agent-message.sh` 실행하여 에이전트 응답 Slack 전송 |
| **PostToolUse** | Agent | `slack-agent-message.sh` 실행하여 에이전트 응답 Slack 전송 |
| **Notification** | 전체 | 알림 발생 시 `notify.sh` 실행 |
| **Stop** | 전체 | `stop-notify.sh` 실행 + `commit-session.sh` 비동기 실행 |

## Rules

| 규칙 | 적용 대상 | 설명 |
|------|----------|------|
| **agents.md** | `agents/**/*.md` | 에이전트 작성 규칙 (네이밍, 역할/도구 정의) |
| **skills.md** | `skills/**/*.md` | 스킬 작성 규칙 (트리거 조건, 코드 템플릿) |
| **teams.md** | `teams/**/*.md` | 팀 구성 규칙 (워크플로, 입출력 형식) |

## Configuration

| 파일 | 설명 |
|------|------|
| **CLAUDE.md** | 프로젝트 규칙 (코드 스타일, 아키텍처 규칙, Git 워크플로, 작업 기록 규칙) |
| **settings.json** | Claude Code 설정 (권한, 모델, 훅, 상태표시줄) |
| **notify.sh** | 알림 훅 스크립트 (macOS/Linux/Windows 시스템 알림 + Slack 웹훅) |
| **statusline.sh** | Claude Code 상태표시줄 스크립트 (작업 디렉토리, git 브랜치, 모델명, 컨텍스트 사용률, 세션명 표시) |

### settings.json 주요 설정

| 설정 | 값 | 설명 |
|------|----|------|
| `defaultMode` | `plan` | 기본 권한 모드 (계획 모드) |
| `effortLevel` | `high` | 에이전트 노력 수준 |
| `teammateMode` | `in-process` | 팀메이트 실행 방식 (인프로세스) |
| `includeCoAuthoredBy` | `true` | 커밋에 Co-Authored-By 자동 추가 |
| `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` | `1` | 에이전트 팀 기능 활성화 (env) |

### 안전 Deny 규칙

```
rm -rf *, git reset --hard*,DROP *, DELETE FROM *
```

위 패턴이 포함된 Bash 명령은 자동 차단되어 사용자 확인을 요구합니다.

### Allow 규칙

```
qmd *
```

QMD 로컬 검색 엔진 명령은 자동 허용됩니다.

### notify.sh 환경 변수

| 환경 변수 | 기본값 | 설명 |
|----------|--------|------|
| `CLAUDE_SYSTEM_ALERT` | `0` | `1`로 설정 시 OS 시스템 알림 활성화 (macOS/Linux/Windows) |
| `SLACK_WEBHOOK_URL` | - | Slack Incoming Webhook URL. 설정 시 Slack 알림 전송 |
| `SLACK_CHANNEL_ID` | - | Slack 멘션 대상 채널/사용자 ID |

```bash
# .zshrc 또는 .bashrc에 추가
export CLAUDE_SYSTEM_ALERT=1
export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/XXX/YYY/ZZZ"
export SLACK_CHANNEL_ID="U01XXXXXXXX"
```

## 기술 스택

- **Backend**: NestJS, TypeORM, Prisma, PostgreSQL, pgvector
- **Frontend**: Next.js (App Router), React, shadcn/ui, Tailwind CSS
- **State Management**: Zustand, TanStack Query
- **Form**: React Hook Form, Zod
- **Animation**: Framer Motion (Motion v11+)
- **Auth**: Auth.js v5
- **Package Manager**: pnpm
- **Testing**: Vitest, Cypress, Supertest
