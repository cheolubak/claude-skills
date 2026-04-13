#!/usr/bin/env bash
# Hook: Stop
# 세션 종료 시 이번 세션에서 memory 파일을 저장했는지 확인한다.
# 저장하지 않았고 git 변경 사항이 있으면 Claude에게 저장을 요청한다. (exit 2)

set -euo pipefail

INPUT=$(cat)
[ -z "$INPUT" ] && INPUT='{}'

# stop_hook_active 체크 (무한 루프 방지)
stop_hook_active=$(echo "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null)
if [ "$stop_hook_active" = "true" ]; then
  exit 0
fi

# 작업 디렉토리 결정
WORK_DIR=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
WORK_DIR="${WORK_DIR:-${CLAUDE_WORKING_DIRECTORY:-$(pwd)}}"

# 프로젝트 메모리 경로 계산
MEMORY_KEY=$(echo "$WORK_DIR" | tr '/' '-')
MEMORY_DIR="$HOME/.claude/projects/$MEMORY_KEY/memory"

# 메모리 디렉토리가 없으면 스킵
if [ ! -d "$MEMORY_DIR" ]; then
  exit 0
fi

# git 변경 사항 여부 확인 (변경이 없으면 저장 불필요)
cd "$WORK_DIR" 2>/dev/null || exit 0
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
  exit 0
fi

# staged + unstaged + untracked 파일 수 확인
changed_count=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
recent_commits=$(git log --oneline --since="4 hours ago" 2>/dev/null | wc -l | tr -d ' ')

# 변경사항이 없으면 저장 불필요
if [ "$changed_count" -eq 0 ] && [ "$recent_commits" -eq 0 ]; then
  exit 0
fi

# 최근 2시간 이내에 수정된 memory 파일 확인
recent_memory=$(find "$MEMORY_DIR" -name "*.md" ! -name "MEMORY.md" -mmin -120 2>/dev/null | head -1)

if [ -n "$recent_memory" ]; then
  # 이미 저장됨
  exit 0
fi

# 저장되지 않은 경우 → Claude에게 저장 요청 (exit 2)
PROJECT_NAME=$(basename "$WORK_DIR")
cat >&2 <<EOF
⚠️  이번 세션 작업이 memory에 저장되지 않았습니다.

프로젝트: $PROJECT_NAME
변경 파일: ${changed_count}개, 최근 커밋: ${recent_commits}건

CLAUDE.md의 '작업 저장 규칙'에 따라 아래 경로에 마크다운 파일을 생성해주세요:
$MEMORY_DIR/project_<작업요약>_$(date +%Y-%m-%d).md

파일 생성 후 MEMORY.md 인덱스도 업데이트하세요.
EOF
exit 2
