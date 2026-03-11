# Claude Code Skills & Agents

Claude Code에서 사용할 수 있는 커스텀 스킬(Skills)과 에이전트(Agents) 모음입니다.

## 프로젝트 구조

```
claude-skills/
├── agents/
│   ├── code-simplifier.md
│   └── nextjs-reviewer.md
└── skills/
    ├── cache-components/
    ├── nestjs-auth/
    ├── nestjs-config/
    ├── nestjs-crud/
    ├── nestjs-database/
    ├── nestjs-error-handling/
    ├── nestjs-semantic-search/
    ├── nestjs-swagger/
    ├── nestjs-testing/
    ├── nestjs-validation/
    ├── nextjs-a11y/
    ├── nextjs-seo/
    ├── nextjs-shadcn/
    ├── react-best-practices/
    ├── server-actions/
    └── tailwind-patterns/
```

## Agents

| 에이전트 | 설명 |
|---------|------|
| **nextjs-reviewer** | Next.js + bun 애플리케이션을 확립된 패턴에 따라 리뷰합니다. 심각한 이슈는 자동 수정하고 권장사항을 보고합니다. |
| **code-simplifier** | 모든 기능을 보존하면서 코드의 명확성, 일관성, 유지보수성을 높이도록 단순화하고 개선합니다. |

## Skills

### NestJS

| 스킬 | 설명 |
|------|------|
| **nestjs-auth** | 인증/인가 설정 (JWT, Guard, 로그인, OAuth) |
| **nestjs-config** | 환경설정 관리 (.env, ConfigModule) |
| **nestjs-crud** | CRUD 모듈 스캐폴딩 (리소스 생성, 페이지네이션) |
| **nestjs-database** | 데이터베이스 패턴 (TypeORM, Prisma, 마이그레이션) |
| **nestjs-error-handling** | 예외 처리 (Exception Filter, 커스텀 예외) |
| **nestjs-semantic-search** | 시맨틱 검색 (pgvector, 임베딩, RAG) |
| **nestjs-swagger** | Swagger/OpenAPI 문서화 |
| **nestjs-testing** | 테스트 작성 (유닛 테스트, E2E 테스트) |
| **nestjs-validation** | DTO 유효성 검증 (class-validator) |

### Next.js

| 스킬 | 설명 |
|------|------|
| **cache-components** | Cache Components (`use cache`) 패턴 (cacheTag, cacheLife) |
| **nextjs-a11y** | 웹 접근성 (WCAG 2.2, ARIA, 키보드 네비게이션) |
| **nextjs-seo** | SEO 최적화 (Metadata API, 사이트맵, JSON-LD) |
| **nextjs-shadcn** | shadcn/ui 컴포넌트 패턴 |
| **server-actions** | Server Actions 패턴 (Zod 유효성 검사, 에러 처리) |

### React / UI

| 스킬 | 설명 |
|------|------|
| **react-best-practices** | React + Next.js 모범 사례 (상태 관리, 성능 최적화) |
| **tailwind-patterns** | Tailwind CSS 패턴 (테마 시스템, 다크모드, 애니메이션) |

## 기술 스택

- **Backend**: NestJS, TypeORM, Prisma, PostgreSQL, pgvector
- **Frontend**: Next.js (App Router), React, shadcn/ui, Tailwind CSS
- **Runtime**: Bun
- **Testing**: Jest, Supertest
