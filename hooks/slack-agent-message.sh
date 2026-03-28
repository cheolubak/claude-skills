#!/usr/bin/env bash
# PostToolUse hook: SendMessage/Agent 에이전트 응답을 Slack으로 자동 전송
# 팀 에이전트 간 토론/승인 대화를 실시간으로 Slack에 공유합니다.
#
# 등록: settings.json → hooks.PostToolUse[matcher="SendMessage"], hooks.PostToolUse[matcher="Agent"]
# 환경변수: CLAUDE_TOOL_INPUT (SendMessage/Agent JSON), CLAUDE_TOOL_RESULT (에이전트 응답)

command -v jq >/dev/null 2>&1 || exit 0

# 에이전트 이름 추출 (SendMessage: to, Agent: subagent_type)
AGENT_NAME=$(echo "$CLAUDE_TOOL_INPUT" | jq -r '.to // .subagent_type // empty' 2>/dev/null)
[ -z "$AGENT_NAME" ] && exit 0

# 팀 에이전트 매핑 (팀에 속하지 않는 에이전트는 무시)
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

# 에이전트 응답 추출
RESPONSE="${CLAUDE_TOOL_RESULT:-}"
[ -z "$RESPONSE" ] && exit 0

# 보낸 메시지에서 Phase/Round 컨텍스트 추출 (SendMessage: content, Agent: prompt)
SENT_MSG=$(echo "$CLAUDE_TOOL_INPUT" | jq -r '.content // .prompt // empty' 2>/dev/null)
PHASE=""

if [ -n "$SENT_MSG" ]; then
  # 최종 판정 패턴 (Round보다 우선)
  if echo "$SENT_MSG" | grep -qiE '최종|종합 판정|채용 판정|Phase\s*2'; then
    PHASE="Phase 2 — 종합 판정"
  # Round N 패턴
  elif ROUND=$(echo "$SENT_MSG" | grep -oiE 'Round\s*[0-9]+' | head -1) && [ -n "$ROUND" ]; then
    # Round 내용 키워드 추출
    ROUND_LABEL=""
    if echo "$SENT_MSG" | grep -qiE '초기|첫|시작'; then
      ROUND_LABEL="초기 분석"
    elif echo "$SENT_MSG" | grep -qiE '도전|보완|검증|반박'; then
      ROUND_LABEL="도전/보완"
    elif echo "$SENT_MSG" | grep -qiE '종합|결론|최종|마무리'; then
      ROUND_LABEL="종합 결론"
    fi

    if [ -n "$ROUND_LABEL" ]; then
      PHASE="토론 — ${ROUND} ${ROUND_LABEL}"
    else
      PHASE="토론 — ${ROUND}"
    fi
  fi
fi

# 분석 대상 추출 시도 (메시지에서 "대상:", "이력서:", "검증:" 패턴)
SUBJECT=""
if [ -n "$SENT_MSG" ]; then
  SUBJECT=$(echo "$SENT_MSG" | grep -oE '(대상|이력서|검증|분석):\s*.+' | head -1 | sed 's/^[^:]*:\s*//')
  # 너무 길면 잘라내기
  if [ ${#SUBJECT} -gt 50 ]; then
    SUBJECT="${SUBJECT:0:50}…"
  fi
fi

# Phase에 완료 표시 추가
if [ -n "$PHASE" ]; then
  PHASE="✅ ${PHASE}"
else
  PHASE="✅ 분석 완료"
fi

# Slack 전송 (기존 slack-team-notify.sh 활용)
HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"
echo "$RESPONSE" | bash "$HOOK_DIR/slack-team-notify.sh" "$AGENT_NAME" "$PHASE" "$SUBJECT" "$TEAM"
