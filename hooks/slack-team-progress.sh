#!/usr/bin/env bash
# 팀 워크플로우 단계별 진행 상황 Slack 알림
# 사용법: bash slack-team-progress.sh <team> <status> <message> [subject] [thread_ts]
#
# status: start(시작), progress(진행중), complete(완료), finish(전체완료)
# thread_ts: 스레드로 답장할 메시지의 타임스탬프 (chat.postMessage API 사용 시)
#
# SLACK_BOT_TOKEN 설정 시 chat.postMessage API를 사용하며,
# 메시지 ts를 stdout으로 반환합니다 (스레드 활용용).
# 미설정 시 Webhook 폴백 (스레드 미지원).
#
# 예시:
#   ts=$(bash "$HOME/.claude/hooks/slack-team-progress.sh" "review-team" "start" "Phase 1 — 토론 시작" "결제 시스템")
#   bash "$HOME/.claude/hooks/slack-team-progress.sh" "review-team" "progress" "토론 중" "" "$ts"

TEAM="${1:-}"
STATUS="${2:-progress}"
MESSAGE="${3:-}"
SUBJECT="${4:-}"
THREAD_TS="${5:-}"

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

if [ -z "$SLACK_CHANNEL_ID" ]; then
  exit 0
fi

SLACK_BOT_TOKEN="${SLACK_BOT_TOKEN:-}"

if [ -z "$SLACK_BOT_TOKEN" ] && [ -z "$SLACK_WEBHOOK_URL" ]; then
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

blocks=$(jq -n \
  --arg text "$text" \
  --arg ts ":clock1: ${timestamp}" \
  '[
    {type: "section", text: {type: "mrkdwn", text: $text}},
    {type: "context", elements: [{type: "mrkdwn", text: $ts}]}
  ]')

if [ -n "$SLACK_BOT_TOKEN" ]; then
  # chat.postMessage API (스레드 지원, ts 반환)
  api_payload=$(jq -n \
    --arg channel "$SLACK_CHANNEL_ID" \
    --argjson blocks "$blocks" \
    --arg fallback "${EMOJI} ${MESSAGE}" \
    '{channel: $channel, blocks: $blocks, text: $fallback}')

  if [ -n "$THREAD_TS" ]; then
    api_payload=$(echo "$api_payload" | jq --arg ts "$THREAD_TS" '. + {thread_ts: $ts}')
  fi

  response=$(curl -s -X POST "https://slack.com/api/chat.postMessage" \
    -H "Authorization: Bearer $SLACK_BOT_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$api_payload")

  # 메시지 ts 출력 (호출자가 스레드용으로 캡처)
  echo "$response" | jq -r '.ts // empty'
else
  # Webhook 폴백 (스레드 미지원)
  payload=$(jq -n --argjson blocks "$blocks" '{blocks: $blocks}')
  curl -s -X POST "$SLACK_WEBHOOK_URL" \
    -H 'Content-Type: application/json' \
    -d "$payload" >/dev/null 2>&1
fi
