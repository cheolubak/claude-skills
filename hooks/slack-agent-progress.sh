#!/usr/bin/env bash
# PreToolUse hook: SendMessage/Agent 전 "진행 중" 상태 Slack 알림
# 에이전트에게 메시지를 보내기 직전에 "요청 중" 상태를 Slack에 전송합니다.
#
# 등록: settings.json → hooks.PreToolUse[matcher="SendMessage"], hooks.PreToolUse[matcher="Agent"]
# 환경변수: CLAUDE_TOOL_INPUT (SendMessage/Agent JSON)

command -v jq >/dev/null 2>&1 || exit 0

# 에이전트 이름 추출 (SendMessage: to, Agent: subagent_type)
AGENT_NAME=$(echo "$CLAUDE_TOOL_INPUT" | jq -r '.to // .subagent_type // empty' 2>/dev/null)
[ -z "$AGENT_NAME" ] && exit 0

# 팀 매핑 (팀에 속하지 않는 에이전트는 무시)
case "$AGENT_NAME" in
  ux-expert|ux-researcher|tech-architect|system-engineer|devils-advocate|risk-analyst|team-reviewer)
    TEAM="review-team"
    ;;
  frontend-tech-lead|frontend-interviewer|project-analyst|resume-critic|hiring-manager|culture-analyst|resume-reviewer)
    TEAM="frontend-resume-review"
    ;;
  *)
    exit 0
    ;;
esac

# 에이전트 역할 매핑
case "$AGENT_NAME" in
  ux-expert)              ROLE="UX 전문가" ;;
  ux-researcher)          ROLE="UX 리서처" ;;
  tech-architect)         ROLE="기술 아키텍트" ;;
  system-engineer)        ROLE="시스템 엔지니어" ;;
  devils-advocate)        ROLE="비판적 검토자" ;;
  risk-analyst)           ROLE="리스크 분석가" ;;
  team-reviewer)          ROLE="최종 검토자" ;;
  frontend-tech-lead)     ROLE="프론트엔드 테크 리드" ;;
  frontend-interviewer)   ROLE="프론트엔드 면접관" ;;
  project-analyst)        ROLE="프로젝트 분석가" ;;
  resume-critic)          ROLE="이력서 비평가" ;;
  hiring-manager)         ROLE="채용 매니저" ;;
  culture-analyst)        ROLE="조직적합성 분석가" ;;
  resume-reviewer)        ROLE="이력서 최종 검토자" ;;
  *)                      ROLE="$AGENT_NAME" ;;
esac

# 메시지에서 Round/Phase 컨텍스트 추출 (SendMessage: content, Agent: prompt)
SENT_MSG=$(echo "$CLAUDE_TOOL_INPUT" | jq -r '.content // .prompt // empty' 2>/dev/null)
CONTEXT=""

if [ -n "$SENT_MSG" ]; then
  # 최종 판정 패턴
  if echo "$SENT_MSG" | grep -qiE '최종|종합 판정|채용 판정|Phase\s*2'; then
    CONTEXT="종합 판정"
  # Round N 패턴
  elif ROUND=$(echo "$SENT_MSG" | grep -oiE 'Round\s*[0-9]+' | head -1) && [ -n "$ROUND" ]; then
    ROUND_LABEL=""
    if echo "$SENT_MSG" | grep -qiE '초기|첫|시작'; then
      ROUND_LABEL="초기 분석"
    elif echo "$SENT_MSG" | grep -qiE '도전|보완|검증|반박'; then
      ROUND_LABEL="도전/보완"
    elif echo "$SENT_MSG" | grep -qiE '종합|결론|최종|마무리'; then
      ROUND_LABEL="종합 결론"
    fi
    if [ -n "$ROUND_LABEL" ]; then
      CONTEXT="${ROUND} ${ROUND_LABEL}"
    else
      CONTEXT="${ROUND}"
    fi
  fi
fi

# 진행 중 메시지 구성
if [ -n "$CONTEXT" ]; then
  MSG="${ROLE}에게 분석 요청 중 — ${CONTEXT}"
else
  MSG="${ROLE}에게 분석 요청 중..."
fi

# 진행 중 알림 전송
HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"
bash "$HOOK_DIR/slack-team-progress.sh" "$TEAM" "progress" "$MSG"
