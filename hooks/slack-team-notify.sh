#!/usr/bin/env bash
# Hook: 에이전트 팀별 Slack 알림 전송
# 사용법: echo "분석 내용" | bash hooks/slack-team-notify.sh <agent-name> <phase> <subject> <team> [thread_ts]
#
# thread_ts: 스레드로 답장할 메시지의 타임스탬프 (chat.postMessage API 사용 시)
#
# SLACK_BOT_TOKEN 설정 시 chat.postMessage API를 사용하며,
# 메시지 ts를 stdout으로 반환합니다.
# 미설정 시 Webhook 폴백 (스레드 미지원).
#
# 팀별 환경변수:
#   review-team            → SLACK_REVIEW_TEAM_WEBHOOK_URL, SLACK_REVIEW_TEAM_CHANNEL_ID
#   frontend-resume-review → SLACK_RESUME_REVIEW_WEBHOOK_URL, SLACK_RESUME_REVIEW_CHANNEL_ID
#   (기본값)                → SLACK_CLAUDE_TEAM_WEBHOOK_URL, SLACK_CLAUDE_TEAM_CHANNEL_ID
#
# 예시:
#   echo "$analysis" | bash "$HOME/.claude/hooks/slack-team-notify.sh" "ux-expert" "UX 토론 — Round 1" "결제 시스템" "review-team" "1234567890.123456"

AGENT_NAME="${1:-agent}"
PHASE="${2:-}"
REVIEW_SUBJECT="${3:-}"
TEAM="${4:-}"
THREAD_TS="${5:-}"

CONTENT=$(cat)
[ -z "$CONTENT" ] && exit 0

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

# 에이전트별 이모지 매핑
case "$AGENT_NAME" in
  ux-expert)       EMOJI=":art:";         ROLE="UX 전문가" ;;
  ux-researcher)   EMOJI=":bar_chart:";   ROLE="UX 리서처" ;;
  tech-architect)  EMOJI=":building_construction:"; ROLE="기술 아키텍트" ;;
  system-engineer) EMOJI=":wrench:";      ROLE="시스템 엔지니어" ;;
  devils-advocate) EMOJI=":imp:";         ROLE="비판적 검토자" ;;
  risk-analyst)    EMOJI=":chart_with_upwards_trend:"; ROLE="리스크 분석가" ;;
  team-reviewer)   EMOJI=":trophy:";      ROLE="최종 검토자" ;;
  frontend-tech-lead)   EMOJI=":computer:";    ROLE="프론트엔드 테크 리드" ;;
  frontend-interviewer) EMOJI=":speaking_head_in_silhouette:"; ROLE="프론트엔드 면접관" ;;
  project-analyst)      EMOJI=":mag_right:";   ROLE="프로젝트 분석가" ;;
  resume-critic)        EMOJI=":detective:";    ROLE="이력서 비평가" ;;
  hiring-manager)       EMOJI=":briefcase:";   ROLE="채용 매니저" ;;
  culture-analyst)      EMOJI=":people_holding_hands:"; ROLE="조직적합성 분석가" ;;
  resume-reviewer)      EMOJI=":clipboard:";   ROLE="이력서 최종 검토자" ;;
  *)               EMOJI=":robot_face:";  ROLE="$AGENT_NAME" ;;
esac

# Markdown → Slack mrkdwn 기본 변환
md_to_slack() {
  sed \
    -e 's/^#### \(.*\)/*\1*/' \
    -e 's/^### \(.*\)/*\1*/' \
    -e 's/^## \(.*\)/*\1*/' \
    -e 's/^# \(.*\)/*\1*/' \
    -e 's/\*\*\([^*]*\)\*\*/*\1*/g'
}

slack_content=$(echo "$CONTENT" | md_to_slack)

# 헤더 구성
header_text="${EMOJI} *${ROLE}*"
if [ -n "$PHASE" ]; then
  header_text="${header_text}  |  ${PHASE}"
fi
if [ -n "$REVIEW_SUBJECT" ]; then
  header_text="${header_text}\n:mag: *대상:* ${REVIEW_SUBJECT}"
fi

timestamp=$(date "+%Y-%m-%d %H:%M")

# 2900자 이하면 단일 메시지, 초과 시 빈 줄 기준으로 분할하여 다중 전송
send_slack_message() {
  local text="$1" is_first="$2"
  local blocks='[]'

  if [ "$is_first" = "1" ]; then
    blocks=$(echo "$blocks" | jq --arg h "$header_text" \
      '. + [{type:"section",text:{type:"mrkdwn",text:$h}}, {type:"divider"}]')
  fi

  blocks=$(echo "$blocks" | jq --arg c "$text" \
    '. + [{type:"section",text:{type:"mrkdwn",text:$c}}]')

  if [ "$is_first" = "1" ]; then
    blocks=$(echo "$blocks" | jq --arg t ":clock1: ${timestamp}" \
      '. + [{type:"context",elements:[{type:"mrkdwn",text:$t}]}]')
  fi

  if [ -n "$SLACK_BOT_TOKEN" ]; then
    local api_payload
    api_payload=$(jq -n \
      --arg channel "$SLACK_CHANNEL_ID" \
      --argjson blocks "$blocks" \
      --arg fallback "${EMOJI} ${ROLE} — ${PHASE}" \
      '{channel: $channel, blocks: $blocks, text: $fallback}')

    if [ -n "$THREAD_TS" ]; then
      api_payload=$(echo "$api_payload" | jq --arg ts "$THREAD_TS" '. + {thread_ts: $ts}')
    fi

    local response
    response=$(curl -s -X POST "https://slack.com/api/chat.postMessage" \
      -H "Authorization: Bearer $SLACK_BOT_TOKEN" \
      -H "Content-Type: application/json" \
      -d "$api_payload")

    echo "$response" | jq -r '.ts // empty'
  else
    local payload
    payload=$(jq -n --argjson blocks "$blocks" '{blocks: $blocks}')
    curl -s -X POST "$SLACK_WEBHOOK_URL" \
      -H 'Content-Type: application/json' \
      -d "$payload" >/dev/null 2>&1
  fi
}

if [ ${#slack_content} -le 2900 ]; then
  send_slack_message "$slack_content" "1"
else
  # 빈 줄 기준으로 단락 분할 후 2900자 이내 청크로 결합
  paragraphs=()
  current_para=""
  while IFS= read -r line; do
    if [ -z "$line" ] && [ -n "$current_para" ]; then
      paragraphs+=("$current_para")
      current_para=""
    elif [ -n "$line" ]; then
      if [ -z "$current_para" ]; then
        current_para="$line"
      else
        current_para="${current_para}"$'\n'"${line}"
      fi
    fi
  done <<< "$slack_content"
  [ -n "$current_para" ] && paragraphs+=("$current_para")

  chunk=""
  is_first="1"
  first_ts=""

  for para in "${paragraphs[@]}"; do
    if [ -z "$chunk" ]; then
      chunk="$para"
    elif [ $(( ${#chunk} + ${#para} + 2 )) -le 2900 ]; then
      chunk="${chunk}"$'\n\n'"${para}"
    else
      ts=$(send_slack_message "$chunk" "$is_first")
      [ "$is_first" = "1" ] && [ -n "$ts" ] && first_ts="$ts"
      is_first="0"
      chunk="$para"
      sleep 1
    fi
  done

  # 마지막 청크 전송
  if [ -n "$chunk" ]; then
    ts=$(send_slack_message "$chunk" "$is_first")
    [ "$is_first" = "1" ] && [ -n "$ts" ] && first_ts="$ts"
  fi

  # 첫 메시지의 ts 출력
  [ -n "$first_ts" ] && echo "$first_ts"
fi
