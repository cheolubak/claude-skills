#!/bin/bash
# Claude Code Notification Engine
# stdin JSON 형식:
#   필수: { "title": "...", "message": "..." }
#   선택: { "blocks": [...] }  → Slack Block Kit 사용
#
# blocks가 있으면 Slack은 Block Kit으로 전송, 없으면 plain text
# 시스템 알림은 항상 title + message 사용

json=$(cat)
message=$(echo "$json" | jq -r '.message // empty')
title=$(echo "$json" | jq -r '.title // "Claude Code"')

if [ -z "$message" ]; then
  exit 0
fi

# --- 시스템 알림 (CLAUDE_SYSTEM_ALERT=1일 때만) ---
if [ "${CLAUDE_SYSTEM_ALERT:-0}" = "1" ]; then
  case "$(uname -s)" in
    Darwin)
      escaped_message=$(echo "$message" | sed 's/\\/\\\\/g; s/"/\\"/g')
      escaped_title=$(echo "$title" | sed 's/\\/\\\\/g; s/"/\\"/g')
      osascript -e "display notification \"$escaped_message\" with title \"$escaped_title\""
      ;;
    MINGW*|MSYS*|CYGWIN*|Windows_NT)
      powershell.exe -Command "[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] > \$null; \$xml = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText02); \$texts = \$xml.GetElementsByTagName('text'); \$texts[0].AppendChild(\$xml.CreateTextNode('$title')) > \$null; \$texts[1].AppendChild(\$xml.CreateTextNode('$message')) > \$null; [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('Claude Code').Show([Windows.UI.Notifications.ToastNotification]::new(\$xml))" 2>/dev/null
      ;;
    Linux)
      notify-send "$title" "$message" 2>/dev/null
      ;;
  esac
fi

# --- Slack 웹훅 ---
SLACK_WEBHOOK_URL="${SLACK_WEBHOOK_URL:-}"
SLACK_CHANNEL_ID="${SLACK_CHANNEL_ID:-}"

if [ -z "$SLACK_WEBHOOK_URL" ] || [ -z "$SLACK_CHANNEL_ID" ]; then
  exit 0
fi

# blocks 필드 존재 여부 확인
has_blocks=$(echo "$json" | jq -e '.blocks | length > 0' >/dev/null 2>&1 && echo "yes" || echo "no")

if [ "$has_blocks" = "yes" ]; then
  # Block Kit 전송
  payload=$(echo "$json" | jq '{blocks: .blocks}')
else
  # Plain text 전송
  payload=$(jq -n --arg text "<@${SLACK_CHANNEL_ID}> $title: $message" '{text: $text, "link_names": 1}')
fi

curl -s -X POST "$SLACK_WEBHOOK_URL" \
  -H 'Content-Type: application/json' \
  -d "$payload"
