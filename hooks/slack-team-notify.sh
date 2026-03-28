#!/usr/bin/env bash
# Hook: 에이전트 팀별 Slack 알림 전송
# 사용법: echo "분석 내용" | bash hooks/slack-team-notify.sh <agent-name> <phase> <subject> <team>
#
# 팀별 환경변수:
#   review-team            → SLACK_REVIEW_TEAM_WEBHOOK_URL, SLACK_REVIEW_TEAM_CHANNEL_ID
#   frontend-resume-review → SLACK_RESUME_REVIEW_WEBHOOK_URL, SLACK_RESUME_REVIEW_CHANNEL_ID
#   (기본값)                → SLACK_CLAUDE_TEAM_WEBHOOK_URL, SLACK_CLAUDE_TEAM_CHANNEL_ID
#
# 예시:
#   echo "$analysis" | bash "$HOME/.claude/hooks/slack-team-notify.sh" "ux-expert" "UX 토론 — Round 1" "결제 시스템" "review-team"

AGENT_NAME="${1:-agent}"
PHASE="${2:-}"
REVIEW_SUBJECT="${3:-}"
TEAM="${4:-}"

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

if [ -z "$SLACK_WEBHOOK_URL" ] || [ -z "$SLACK_CHANNEL_ID" ]; then
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

# Slack section 텍스트 제한 (3000자)
if [ ${#slack_content} -gt 2900 ]; then
  slack_content="${slack_content:0:2900}…"
fi

# Block Kit 구성
blocks='[]'

# 1. 헤더: 에이전트 역할 + Phase/Round 정보
header_text="${EMOJI} *${ROLE}*"
if [ -n "$PHASE" ]; then
  header_text="${header_text}  |  ${PHASE}"
fi
if [ -n "$REVIEW_SUBJECT" ]; then
  header_text="${header_text}\n:mag: *대상:* ${REVIEW_SUBJECT}"
fi

blocks=$(echo "$blocks" | jq --arg h "$header_text" \
  '. + [{type:"section",text:{type:"mrkdwn",text:$h}}]')

# 2. 구분선 + 분석 내용
blocks=$(echo "$blocks" | jq --arg c "$slack_content" \
  '. + [{type:"divider"}, {type:"section",text:{type:"mrkdwn",text:$c}}]')

# 3. 컨텍스트 (타임스탬프)
timestamp=$(date "+%Y-%m-%d %H:%M")
blocks=$(echo "$blocks" | jq --arg t ":clock1: ${timestamp}" \
  '. + [{type:"context",elements:[{type:"mrkdwn",text:$t}]}]')

# 전송
payload=$(jq -n --argjson blocks "$blocks" '{blocks: $blocks}')

curl -s -X POST "$SLACK_WEBHOOK_URL" \
  -H 'Content-Type: application/json' \
  -d "$payload" >/dev/null 2>&1
