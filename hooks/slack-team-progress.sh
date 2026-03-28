#!/usr/bin/env bash
# 팀 워크플로우 단계별 진행 상황 Slack 알림
# 사용법: bash slack-team-progress.sh <team> <status> <message> [subject]
#
# status: start(시작), progress(진행중), complete(완료), finish(전체완료)
#
# 예시:
#   bash "$HOME/.claude/hooks/slack-team-progress.sh" "review-team" "start" "Phase 1 — UX/Tech/Risk 3개 파트 병렬 토론" "결제 시스템"
#   bash "$HOME/.claude/hooks/slack-team-progress.sh" "review-team" "complete" "UX 파트 토론 완료"
#   bash "$HOME/.claude/hooks/slack-team-progress.sh" "review-team" "finish" "전체 리뷰 완료"

TEAM="${1:-}"
STATUS="${2:-progress}"
MESSAGE="${3:-}"
SUBJECT="${4:-}"

[ -z "$MESSAGE" ] && exit 0
command -v jq >/dev/null 2>&1 || exit 0

# 팀별 Slack 환경변수 선택
case "$TEAM" in
  review-team)
    SLACK_WEBHOOK_URL="${SLACK_REVIEW_TEAM_WEBHOOK_URL:-${SLACK_CLAUDE_TEAM_WEBHOOK_URL:-}}"
    SLACK_CHANNEL_ID="${SLACK_REVIEW_TEAM_CHANNEL_ID:-${SLACK_CLAUDE_TEAM_CHANNEL_ID:-}}"
    ;;
  frontend-resume-review)
    SLACK_WEBHOOK_URL="${SLACK_RESUME_REVIEW_WEBHOOK_URL:-${SLACK_CLAUDE_TEAM_WEBHOOK_URL:-}}"
    SLACK_CHANNEL_ID="${SLACK_RESUME_REVIEW_CHANNEL_ID:-${SLACK_CLAUDE_TEAM_CHANNEL_ID:-}}"
    ;;
  *)
    SLACK_WEBHOOK_URL="${SLACK_CLAUDE_TEAM_WEBHOOK_URL:-}"
    SLACK_CHANNEL_ID="${SLACK_CLAUDE_TEAM_CHANNEL_ID:-}"
    ;;
esac

if [ -z "$SLACK_WEBHOOK_URL" ] || [ -z "$SLACK_CHANNEL_ID" ]; then
  exit 0
fi

# 상태별 이모지
case "$STATUS" in
  start)    EMOJI=":rocket:" ;;
  progress) EMOJI=":hourglass_flowing_sand:" ;;
  complete) EMOJI=":white_check_mark:" ;;
  finish)   EMOJI=":checkered_flag:" ;;
  *)        EMOJI=":information_source:" ;;
esac

# Block Kit 구성
text="${EMOJI} *${MESSAGE}*"
if [ -n "$SUBJECT" ]; then
  text="${text}\n:mag: *대상:* ${SUBJECT}"
fi

timestamp=$(date "+%Y-%m-%d %H:%M")

payload=$(jq -n \
  --arg text "$text" \
  --arg ts ":clock1: ${timestamp}" \
  '{blocks: [
    {type: "section", text: {type: "mrkdwn", text: $text}},
    {type: "context", elements: [{type: "mrkdwn", text: $ts}]}
  ]}')

curl -s -X POST "$SLACK_WEBHOOK_URL" \
  -H 'Content-Type: application/json' \
  -d "$payload" >/dev/null 2>&1
