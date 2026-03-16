# Claude Code Skills & Agents

Claude Code에서 사용할 수 있는 커스텀 스킬(Skills)과 에이전트(Agents) 모음입니다.

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

# setting settings.json
$ ln -s $(pwd)/settings.json $HOME/.claude/settings.json

# setting notify.sh
$ ln -s $(pwd)/notify.sh $HOME/.claude/notify.sh
```

## 프로젝트 구조

```
claude-skills/
├── agents/
│   ├── code-simplifier.md
│   ├── devils-advocate.md
│   ├── nestjs-reviewer.md
│   ├── nextjs-reviewer.md
│   ├── team-reviewer.md
│   ├── tech-architect.md
│   └── ux-expert.md
├── rules/
│   ├── agents.md
│   ├── skills.md
│   └── teams.md
├── skills/
│   ├── cache-components/
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
│   ├── nextjs-i18n/
│   ├── nextjs-monorepo/
│   ├── nextjs-seo/
│   ├── nextjs-shadcn/
│   ├── nextjs-testing/
│   ├── react-best-practices/
│   ├── review-team/
│   ├── server-actions/
│   └── tailwind-patterns/
├── teams/
│   └── review-team.md
├── notify.sh
└── settings.json
```

## Agents

| 에이전트 | 설명 |
|---------|------|
| **nextjs-reviewer** | Next.js + pnpm 애플리케이션을 확립된 패턴에 따라 리뷰합니다. 심각한 이슈는 자동 수정하고 권장사항을 보고합니다. |
| **nestjs-reviewer** | NestJS 애플리케이션을 확립된 패턴에 따라 리뷰합니다. 심각한 이슈는 자동 수정하고 권장사항을 보고합니다. |
| **code-simplifier** | 모든 기능을 보존하면서 코드의 명확성, 일관성, 유지보수성을 높이도록 단순화하고 개선합니다. |
| **ux-expert** | UX 전문가 - 사용자 경험, 사용성, 접근성, 사용자 흐름을 분석하고 개선안을 제시합니다. |
| **tech-architect** | 기술 아키텍트 - 시스템 설계, 확장성, 성능, 기술 스택 선택을 분석하고 아키텍처 의사결정을 기록합니다. |
| **devils-advocate** | 비판적 검토자 - 가정을 도전하고, 위험을 탐색하며, 맹점을 발견하여 의사결정의 질을 높입니다. |
| **team-reviewer** | 최종 검토자 - 모든 관점(UX, 기술, 리스크)을 종합하여 충돌을 조율하고 실행 가능한 결론을 도출합니다. |

## Teams

| 팀 | 멤버 | 설명 |
|----|------|------|
| **review-team** | ux-expert, tech-architect, devils-advocate, team-reviewer | 4인 다각도 리뷰 팀. Phase 1에서 UX/기술/리스크를 병렬 분석하고, Phase 2에서 종합 판정을 도출합니다. |

사용법: `/review-team [분석 대상]`

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
| **tailwind-patterns** | Tailwind CSS 패턴 (테마 시스템, 다크모드, 애니메이션) |

## Rules

| 규칙 | 적용 대상 | 설명 |
|------|----------|------|
| **agents.md** | `agents/**/*.md` | 에이전트 작성 규칙 (네이밍, 역할/도구 정의) |
| **skills.md** | `skills/**/*.md` | 스킬 작성 규칙 (트리거 조건, 코드 템플릿) |
| **teams.md** | `teams/**/*.md` | 팀 구성 규칙 (워크플로, 입출력 형식) |

## Configuration

| 파일 | 설명 |
|------|------|
| **settings.json** | Claude Code 설정 (권한, 모델, 훅, 상태표시줄) |
| **notify.sh** | 알림 훅 스크립트 (macOS/Linux/Windows 시스템 알림 + Slack 웹훅) |

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
- **Package Manager**: pnpm
- **Testing**: Vitest, Cypress, Supertest
