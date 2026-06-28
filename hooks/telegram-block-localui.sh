#!/usr/bin/env bash
# PreToolUse hook (matcher: AskUserQuestion):
# 텔레그램 세션 마커(telegram-ack.sh가 생성)가 있으면 AskUserQuestion(로컬 선택 UI)
# 호출을 하드 차단한다. 텔레그램 사용자는 로컬 터미널 UI를 볼 수 없으므로,
# Claude가 telegram reply로 질문하도록 deny 사유로 유도한다.
#
# 마커는 세션별(session_id)로 분리되며, 로컬 프롬프트가 오면 telegram-ack.sh가 제거한다.
# 따라서 로컬 세션/작업에서는 이 훅이 아무것도 차단하지 않는다.

input=$(cat)

session_id=$(printf '%s' "$input" | jq -r '.session_id // ""' 2>/dev/null)
marker="/tmp/claude-tg-session-${session_id}.marker"

if [ -n "$session_id" ] && [ -f "$marker" ]; then
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: "텔레그램 세션입니다. AskUserQuestion(로컬 선택 UI)은 텔레그램 사용자에게 보이지 않으므로 사용할 수 없습니다. 대신 telegram reply 도구로 질문을 보내세요. 선택지는 1) 2) 3) 처럼 번호 텍스트로 제시하고, 질문을 보낸 뒤에는 턴을 종료하여 사용자의 다음 텔레그램 메시지를 답으로 기다리세요(그 사이 추측으로 진행하지 마세요)."
    }
  }'
  exit 0
fi

exit 0
