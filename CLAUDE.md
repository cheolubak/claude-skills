# 프로젝트 규칙

- Always use pnpm, not npm

# 빌드 & 테스트 명령어

- Build: `pnpm build`
- Test: `pnpm test`
- Lint: `pnpm lint`
- Format: `pnpm format`

# 코드 스타일

- TypeScript strict mode
- async/await 사용 (not .then())
- 2-space indentation

# 아키텍처 규칙

## NestJS

- 비즈니스 로직은 Service에, Controller는 thin
- DTO로 입력 검증, custom exception filter 사용

## Next.js

- Server Component 기본, Client는 최소화
- Server Actions로 mutation 처리

# Git 워크플로

- 브랜치: feature/*, fix/*, chore/*
- 커밋 메시지: imperative mood (한글 가능)