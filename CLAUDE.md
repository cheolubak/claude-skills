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

# 작업 기록

작업 완료 후 반드시 다음 두 가지를 수행:

1. **Memory 저장**: 작업 내용을 memory에 `project` 타입으로 저장 (무엇을 왜 변경했는지 요약)
2. **Work Log 기록**: `work-log.md` 파일에 날짜별로 작업 내용 추가

## Work Log 형식

```markdown
## YYYY-MM-DD

### [작업 제목]
- **변경 파일**: 수정된 파일 목록
- **내용**: 무엇을 왜 변경했는지 간략 요약
- **커밋**: 커밋 해시 (커밋한 경우)
```