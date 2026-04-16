#!/usr/bin/env bash
# PostToolUse hook: Skill 도구 호출 시 사용 내역을 JSONL 파일에 기록
#
# 등록: settings.json → hooks.PostToolUse[matcher="Skill"]
# 환경변수:
#   CLAUDE_TOOL_INPUT  - {"skill": "skill-name", "args": "..."}
#   CLAUDE_SESSION_ID  - 현재 세션 ID
#   CLAUDE_PROJECT_DIR - 현재 프로젝트 디렉토리

LOG_FILE="$HOME/.claude/skill-usage.jsonl"

command -v jq >/dev/null 2>&1 || exit 0
[ -z "$CLAUDE_TOOL_INPUT" ] && exit 0

# 스킬 이름 추출
SKILL_NAME=$(echo "$CLAUDE_TOOL_INPUT" | jq -r '.skill // empty' 2>/dev/null)
[ -z "$SKILL_NAME" ] && exit 0

# 스킬 인자 추출
SKILL_ARGS=$(echo "$CLAUDE_TOOL_INPUT" | jq -r '.args // ""' 2>/dev/null)

# 타임스탬프 (ISO 8601)
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# 프로젝트 디렉토리 (환경변수 또는 CWD)
PROJECT="${CLAUDE_PROJECT_DIR:-${PWD:-unknown}}"

# 세션 ID
SESSION="${CLAUDE_SESSION_ID:-unknown}"

# JSONL 로그 기록
jq -n -c \
  --arg skill "$SKILL_NAME" \
  --arg args "$SKILL_ARGS" \
  --arg ts "$TIMESTAMP" \
  --arg project "$PROJECT" \
  --arg session "$SESSION" \
  '{skill: $skill, args: $args, timestamp: $ts, project: $project, session: $session}' \
  >> "$LOG_FILE"
