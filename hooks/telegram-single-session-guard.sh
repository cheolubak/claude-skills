#!/usr/bin/env bash
# telegram-single-session-guard.sh
#
# SessionStart 훅. 텔레그램 봇은 단일 라이브 세션에 종속되는 구조라(Bot API에 큐 없음),
# 여러 Claude 세션이 동시에 telegram 채널을 잡으면 하나의 봇 토큰으로 getUpdates polling을
# 경쟁해 메시지가 다른 세션으로 라우팅되거나 409로 유실된다(= "가끔 응답 없음"의 1순위 원인).
#
# 이 훅은 그것을 *막지는* 못한다(STDIO MCP는 세션마다 자동 기동됨). 대신 `--channels
# plugin:telegram` 플래그가 붙은 세션이 2개 이상이면 세션 시작 시 경고해, 사용자가 즉시
# 인지하고 텔레그램을 한 세션에서만 쓰도록 유지하게 한다.
#
# 판정 기준: "claude 프로세스 개수"가 아니라 "telegram 채널을 가진 프로세스 개수".
# 사용자는 cmux로 다중 세션을 의도적으로 운영하므로 전자로는 오탐이 난다.
#
# macOS 기본 bash 3.2 호환을 위해 mapfile/연관배열을 쓰지 않는다.

set -u

# telegram 채널을 보유한 실행 중 세션 ID 목록 (이 세션 자신 포함, 중복 제거, 공백 구분)
SESSION_IDS=$(
  ps -axo command 2>/dev/null \
    | grep -F -- '--channels' \
    | grep -F 'plugin:telegram' \
    | grep -v grep \
    | grep -oE 'session-id [a-f0-9-]+' \
    | sed 's/session-id //' \
    | sort -u \
    | tr '\n' ' '
)

# 공백 기준 단어 수 = 세션 수
COUNT=0
for _id in $SESSION_IDS; do
  COUNT=$((COUNT + 1))
done

# 경쟁이 없으면(0 또는 1) 조용히 통과
if [ "$COUNT" -lt 2 ]; then
  exit 0
fi

# 2개 이상 → 토큰 경쟁 발생. 사용자에게 경고 + 해당 세션 ID 안내.
# 표시용으로 끝 공백 제거하고 ", "로 연결
IDS=$(printf '%s' "$SESSION_IDS" | sed 's/ *$//' | sed 's/ /, /g')

# 메시지에는 JSON에서 이스케이프가 필요한 문자(" 와 \)를 쓰지 않는다.
# 동적 값(UUID, 숫자)도 JSON-safe하므로 따옴표로 감싸 그대로 출력해도 안전하다.
MSG="⚠️ 텔레그램 채널을 가진 Claude 세션이 ${COUNT}개 감지되었습니다 (${IDS}). 하나의 봇 토큰을 여러 세션이 경쟁하면 메시지가 다른 세션으로 라우팅되거나 유실됩니다(가끔 응답 없음의 원인). 텔레그램은 한 세션에서만 사용하도록 나머지 세션을 종료하세요."

printf '{"systemMessage": "%s"}\n' "$MSG"
exit 0
