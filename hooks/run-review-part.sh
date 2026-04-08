#!/usr/bin/env bash
# 독립 세션으로 토론 파트를 실행합니다.
# 사용법: bash run-review-part.sh <team> <part> <primary-agent> <secondary-agent> <subject-file> <output-dir>
#
# 예시:
#   bash run-review-part.sh "review-team" "UX" "ux-expert" "ux-researcher" "/tmp/review/subject.md" "/tmp/review"
#
# 각 라운드를 개별 claude -p 세션으로 실행하고,
# 라운드 간 결과를 bash에서 전달하며 Slack 알림을 직접 전송합니다.
#
# 도전자(Round 2)는 Sonnet 모델로 실행되어 토큰 비용을 절감합니다.

set -euo pipefail

TEAM="${1:?team required}"
PART="${2:?part name required}"
PRIMARY="${3:?primary agent required}"
SECONDARY="${4:?secondary agent required}"
SUBJECT_FILE="${5:?subject file required}"
OUTPUT_DIR="${6:?output dir required}"

HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"

# 라운드 결과를 ## 헤더 기준으로 분할하여 Slack 스레드에 개별 전송
send_by_sections() {
  local agent="$1" phase="$2" team="$3" thread="$4"
  local content
  content=$(cat)
  [ -z "$content" ] && return

  local tmpdir
  tmpdir=$(mktemp -d)

  # ## 또는 # 헤더 기준으로 파일 분할
  echo "$content" | awk -v dir="$tmpdir" '
    /^##? [^#]/ {
      idx++
      if (out != "") close(out)
      out = dir "/s_" sprintf("%03d", idx) ".txt"
    }
    {
      if (idx == 0) { idx++; out = dir "/s_" sprintf("%03d", idx) ".txt" }
      print >> out
    }
  '

  local count
  count=$(ls "$tmpdir"/s_*.txt 2>/dev/null | wc -l | tr -d ' ')

  if [ "$count" -le 1 ]; then
    echo "$content" | bash "$HOOK_DIR/slack-team-notify.sh" \
      "$agent" "$phase" "" "$team" "$thread" >/dev/null
  else
    for f in "$tmpdir"/s_*.txt; do
      [ -f "$f" ] || continue
      local header
      header=$(head -1 "$f" | sed 's/^#* //')
      cat "$f" | bash "$HOOK_DIR/slack-team-notify.sh" \
        "$agent" "${phase} — ${header}" "" "$team" "$thread" >/dev/null
      sleep 1
    done
  fi

  rm -rf "$tmpdir"
}

# 분석 대상 읽기
SUBJECT=$(cat "$SUBJECT_FILE" 2>/dev/null)
[ -z "$SUBJECT" ] && echo "ERROR: subject file empty" >&2 && exit 1

mkdir -p "$OUTPUT_DIR"

# 시작 알림 (ts 캡처하여 스레드 활용)
START_TS=$(bash "$HOOK_DIR/slack-team-progress.sh" "$TEAM" "progress" "${PART} 파트 토론 시작")
THREAD="${START_TS:-}"

# ─── Round 1: 주도자 초기 분석 ───
bash "$HOOK_DIR/slack-team-progress.sh" "$TEAM" "progress" "${PART} — Round 1 초기 분석 요청 중" "" "$THREAD" >/dev/null

ROUND1=$(CMUX_CLAUDE_HOOKS_DISABLED=1 claude -p "$(cat <<PROMPT
너는 ${PRIMARY} 역할이다. 코드 작성이 아닌 분석/리서치만 수행한다.

## 분석 대상
${SUBJECT}

위 대상에 대해 Round 1 초기 분석을 수행해주세요.
해당 영역의 모든 관점에서 철저히 분석하고, 구체적인 근거와 함께 핵심 권고사항을 제시해주세요.
PROMPT
)" --output-format text 2>/dev/null || true)

if [ -n "$ROUND1" ]; then
  echo "$ROUND1" | send_by_sections "$PRIMARY" "✅ Round 1 초기 분석" "$TEAM" "$THREAD"
fi

# ─── Round 2: 도전자 반박/보완 (Sonnet) ───
bash "$HOOK_DIR/slack-team-progress.sh" "$TEAM" "progress" "${PART} — Round 2 도전/보완 요청 중" "" "$THREAD" >/dev/null

ROUND2=$(CMUX_CLAUDE_HOOKS_DISABLED=1 claude -p "$(cat <<PROMPT
너는 ${SECONDARY} 역할이다. 코드 작성이 아닌 분석/리서치만 수행한다.

## 분석 대상
${SUBJECT}

## Round 1 — ${PRIMARY}의 초기 분석
${ROUND1}

위 Round 1 분석에 대해 Round 2 도전과 보완을 수행해주세요.
동의/보강할 부분과 도전/보완할 부분을 구분하여 제시해주세요.
PROMPT
)" --model sonnet --output-format text 2>/dev/null || true)

if [ -n "$ROUND2" ]; then
  echo "$ROUND2" | send_by_sections "$SECONDARY" "✅ Round 2 도전/보완" "$TEAM" "$THREAD"
fi

# ─── Round 3: 주도자 종합 결론 ───
bash "$HOOK_DIR/slack-team-progress.sh" "$TEAM" "progress" "${PART} — Round 3 종합 결론 도출 중" "" "$THREAD" >/dev/null

ROUND3=$(CMUX_CLAUDE_HOOKS_DISABLED=1 claude -p "$(cat <<PROMPT
너는 ${PRIMARY} 역할이다. 코드 작성이 아닌 분석/리서치만 수행한다.

## 분석 대상
${SUBJECT}

## Round 1 — 본인의 초기 분석
${ROUND1}

## Round 2 — ${SECONDARY}의 도전/보완
${ROUND2}

위 토론을 바탕으로 Round 3 종합 결론을 도출해주세요.
Round 2 피드백 중 수용한 것과 수용하지 않은 것을 명시하고,
최종 분석 결론과 핵심 권고사항을 제시해주세요.
PROMPT
)" --output-format text 2>/dev/null || true)

if [ -n "$ROUND3" ]; then
  echo "$ROUND3" | send_by_sections "$PRIMARY" "✅ Round 3 종합 결론" "$TEAM" "$THREAD"
fi

# ─── 결과 저장 ───
if [ -n "$ROUND3" ]; then
  echo "$ROUND3" > "$OUTPUT_DIR/${PART}.md"
fi

# 완료 알림 (독립 메시지)
if [ -f "$OUTPUT_DIR/${PART}.md" ]; then
  COMPLETE_TS=$(bash "$HOOK_DIR/slack-team-progress.sh" "$TEAM" "complete" "${PART} 파트 토론 완료 (3/3 라운드)")

  if [ -n "$COMPLETE_TS" ]; then
    cat "$OUTPUT_DIR/${PART}.md" | send_by_sections \
      "$PRIMARY" ":memo: ${PART} 최종 결론" "$TEAM" "$COMPLETE_TS"
  fi
else
  bash "$HOOK_DIR/slack-team-progress.sh" "$TEAM" "complete" "${PART} 파트 토론 완료 (결과 파일 미생성 — 수동 확인 필요)" >/dev/null
fi
