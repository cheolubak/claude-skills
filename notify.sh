#!/bin/bash
# Claude Code Notification Hook
# stdin으로 JSON을 받아서 macOS 알림 + Slack 웹훅 전송

json=$(cat)
message=$(echo "$json" | jq -r '.message // empty')
title=$(echo "$json" | jq -r '.title // "Claude Code"')

if [ -z "$message" ]; then
  exit 0
fi

# 시스템 알림 (CLAUDE_SYSTEM_ALERT=1일 때만)
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

# Slack 웹훅
SLACK_WEBHOOK_URL="${SLACK_WEBHOOK_URL:-}"
SLACK_CHANNEL_ID="${SLACK_CHANNEL_ID:-}"

if [ -n "$SLACK_WEBHOOK_URL" ] && [ -n "$SLACK_CHANNEL_ID" ]; then
  curl -s -X POST "$SLACK_WEBHOOK_URL" \
    -H 'Content-Type: application/json' \
    -d "$(jq -n --arg text "<@${SLACK_CHANNEL_ID}> $title: $message" '{text: $text, "link_names": 1}')"
fi
