#!/usr/bin/env bash
# UserPromptSubmit hook: 텔레그램에서 들어온 메시지를 감지하면,
#   1) Claude가 다른 작업보다 먼저 "확인 반응(이모지/메시지)"을 남기도록 지시를 주입하고,
#   2) 작업 중 진행 방향/선택을 로컬 UI(AskUserQuestion)가 아닌 telegram reply로 묻도록 지시하며,
#   3) 텔레그램 세션 마커 파일을 만들어 PreToolUse 훅(telegram-block-localui.sh)이
#      AskUserQuestion 호출을 하드 차단할 수 있게 한다.
#
# 텔레그램이 아닌 로컬 프롬프트가 오면 마커를 제거하여 로컬 AskUserQuestion을 다시 허용한다.
#
# hook(셸 명령)은 MCP 도구(react/reply)를 직접 호출할 수 없으므로,
# additionalContext로 지시만 주입하고 실제 react/reply 호출은 Claude가 수행한다.

input=$(cat)

# --- 검증용 디버그 센티넬 (firing/필드명/태그 포함 확인용) ---
# 텔레그램 메시지가 정말 UserPromptSubmit을 발화시키고 .prompt에 태그가 들어오는지
# 확인이 끝나면 아래 한 줄을 삭제해도 된다.
printf '%s\n---\n' "$input" >> /tmp/tg-ack-debug.txt 2>/dev/null

prompt=$(printf '%s' "$input" | jq -r '.prompt // ""' 2>/dev/null)
session_id=$(printf '%s' "$input" | jq -r '.session_id // ""' 2>/dev/null)
marker="/tmp/claude-tg-session-${session_id}.marker"

case "$prompt" in
  *'source="telegram"'*)
    # 텔레그램 세션 마커 생성 → PreToolUse 훅이 AskUserQuestion(로컬 선택 UI)을 차단
    [ -n "$session_id" ] && : > "$marker" 2>/dev/null

    jq -n '{
      hookSpecificOutput: {
        hookEventName: "UserPromptSubmit",
        additionalContext: "이 메시지는 Telegram 채널에서 수신되었습니다.\n\n(1) 무조건 가장 먼저, 다른 어떤 도구 호출이나 응답보다 앞서 확인 반응을 남기세요: 메시지의 <channel> 태그에서 chat_id와 message_id를 추출한 뒤, telegram react 도구로 해당 message_id에 확인 이모지(예: 👀)를 남기거나 reply 도구로 짧은 확인 메시지를 보내세요. 이 확인 반응을 먼저 보낸 다음에야 실제 요청 작업을 진행하세요.\n\n(2) 작업 도중 사용자에게 진행 방향·선택지·승인 여부를 물어야 할 때는 절대 AskUserQuestion 같은 로컬 UI 도구를 쓰지 마세요. 로컬 터미널에만 표시되어 텔레그램 사용자는 볼 수 없습니다(이 세션에서는 PreToolUse 훅이 AskUserQuestion을 차단합니다). 대신 telegram reply 도구로 질문을 보내되, 선택지는 1) 2) 3) 처럼 번호 텍스트로 제시하세요. 질문을 보낸 뒤에는 턴을 종료하여 사용자의 다음 텔레그램 메시지를 답으로 기다리고, 그 사이 추측으로 작업을 진행하지 마세요."
      }
    }'
    ;;
  *)
    # 텔레그램이 아닌 로컬 프롬프트 → 마커 제거(로컬 AskUserQuestion 허용)
    [ -n "$session_id" ] && rm -f "$marker" 2>/dev/null
    ;;
esac

exit 0
