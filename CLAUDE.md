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

# Telegram

- Telegram 채널에서 메시지를 받으면(`<channel source="telegram" ...>`), 무조건 가장 먼저 — 다른 도구 호출이나 응답보다 앞서 — telegram `react`로 확인 이모지(예: 👀)를 남기거나 `reply`로 짧은 확인 메시지를 보낸 뒤 실제 작업을 진행한다.
- Telegram 채널에서 시작된 작업을 처리하는 동안 사용자에게 **진행 방향·선택지·승인 여부**를 물어야 할 때는 `AskUserQuestion` 같은 로컬 UI 도구를 절대 쓰지 않는다(로컬 터미널에만 표시되어 텔레그램 사용자는 볼 수 없다). 대신 telegram `reply`로 질문하며, 선택지는 `1) 2) 3)` 번호 텍스트로 제시한다. 질문을 보낸 뒤에는 턴을 종료하여 사용자의 다음 텔레그램 메시지를 답으로 기다리고, 그 사이 추측으로 작업을 진행하지 않는다. (`AskUserQuestion`은 PreToolUse 훅이 텔레그램 세션에서 차단한다.)

# Git 워크플로

- 브랜치: feature/*, fix/*, chore/*
- 커밋 메시지: imperative mood (한글 가능)
- 머지: 무조건 rebase 방식으로만 머지한다 (merge commit 금지). PR 머지 시 "Rebase and merge"를 사용하고, 로컬 통합 시 `git rebase`로 base 브랜치 위에 재배치한 뒤 fast-forward로 머지한다. `git merge`로 merge commit을 생성하지 않는다.

# 작업 기록

작업 완료 후 반드시 다음 두 가지를 수행:

1. **Memory 저장**: 작업 내용을 memory에 `project` 타입으로 저장 (무엇을 왜 변경했는지 요약)
2. **Work Log 기록**: `work-log.md` 파일에 날짜별로 작업 내용 추가

> **예외**: 프로젝트 이름(또는 최상위 디렉토리명)이 `ttc-`로 시작하는 경우에는 `work-log.md`를 생성하거나 기록하지 않는다. Memory 저장은 그대로 수행한다.

## Work Log 형식

```markdown
## YYYY-MM-DD

### [작업 제목]
- **변경 파일**: 수정된 파일 목록
- **내용**: 무엇을 왜 변경했는지 간략 요약
- **커밋**: 커밋 해시 (커밋한 경우)
```