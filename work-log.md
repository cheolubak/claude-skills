# Work Log

## 2026-03-16

### 규칙 파일 불일치 수정 및 보안 개선
- **변경 파일**: `rules/skills.md`, `rules/agents.md`, `notify.sh`, `settings.json`
- **내용**: 스킬 규칙의 파일명 불일치(instruction.md → SKILL.md) 수정, 에이전트 규칙을 실제 frontmatter 지원 필드에 맞게 변경, notify.sh osascript 이스케이프 처리 추가, 존재하지 않는 statusline-command.sh 참조 제거
- **커밋**: `7504c70`

### 작업 기록 시스템 추가
- **변경 파일**: `CLAUDE.md`, `work-log.md`
- **내용**: 작업 완료 시 memory 저장 + work-log.md 기록을 자동으로 수행하도록 CLAUDE.md에 규칙 추가
