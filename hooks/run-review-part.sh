#!/usr/bin/env bash
# 독립 세션으로 파트 분석을 실행합니다.
# 사용법: bash run-review-part.sh <team> <part> <agent> <subject-file> <output-dir>
#
# 예시:
#   bash run-review-part.sh "review-team" "UX" "ux-expert" "/tmp/review/subject.md" "/tmp/review"
#
# 각 파트는 독립된 claude -p 세션에서 1인 심층 분석을 수행하고,
# 최종 결론을 <output-dir>/<part>.md에 저장합니다.
#
# Slack 스레드:
#   SLACK_BOT_TOKEN 설정 시, "분석 시작" 메시지의 스레드에 분석 내용이,
#   "분석 완료" 메시지의 스레드에 최종 결론이 자동으로 게시됩니다.

set -euo pipefail

TEAM="${1:?team required}"
PART="${2:?part name required}"
AGENT="${3:?agent required}"
SUBJECT_FILE="${4:?subject file required}"
OUTPUT_DIR="${5:?output dir required}"

# 분석 대상 읽기
SUBJECT=$(cat "$SUBJECT_FILE" 2>/dev/null)
[ -z "$SUBJECT" ] && echo "ERROR: subject file empty" >&2 && exit 1

mkdir -p "$OUTPUT_DIR"

# 시작 알림 (ts 캡처하여 스레드 활용)
START_TS=$(bash "$HOME/.claude/hooks/slack-team-progress.sh" "$TEAM" "progress" "${PART} 파트 분석 시작")

# SLACK_THREAD_TS를 export하면 claude -p 세션의 훅들이 스레드로 전송
export SLACK_THREAD_TS="${START_TS:-}"

# 프롬프트 구성 (heredoc → 변수)
read -r -d '' PROMPT <<ENDPROMPT || true
너는 ${TEAM}의 ${PART} 파트 분석가다. 코드 작성이 아닌 분석/리서치만 수행한다.

## 분석 대상
${SUBJECT}

## 수행 절차

Agent 도구로 ${AGENT} 에이전트(subagent_type="${AGENT}")를 실행한다.
프롬프트에 다음을 포함한다:
- 분석 대상 전문
- "심층 분석을 수행해주세요. 해당 영역의 모든 관점에서 철저히 분석하고, 구체적인 근거와 함께 핵심 권고사항을 제시해주세요"

${AGENT}의 응답 전문을 Write 도구로 다음 파일에 저장한다:
${OUTPUT_DIR}/${PART}.md

## 중요 규칙
- Agent 도구만 사용하고 코드 작성/수정은 하지 말 것
- 에이전트 응답을 요약하지 말고 전문을 저장할 것
ENDPROMPT

# claude -p 세션 실행
claude -p "$PROMPT" --output-format text 2>/dev/null || true

# 스레드 해제 (완료 메시지는 독립 메시지로 전송)
unset SLACK_THREAD_TS

# 결과 파일 확인 및 완료 알림
if [ -f "$OUTPUT_DIR/${PART}.md" ]; then
  COMPLETE_TS=$(bash "$HOME/.claude/hooks/slack-team-progress.sh" "$TEAM" "complete" "${PART} 파트 분석 완료")

  # 완료 메시지의 스레드에 최종 결론 게시
  if [ -n "$COMPLETE_TS" ]; then
    cat "$OUTPUT_DIR/${PART}.md" | bash "$HOME/.claude/hooks/slack-team-notify.sh" \
      "$AGENT" ":memo: ${PART} 분석 결론" "" "$TEAM" "$COMPLETE_TS" >/dev/null
  fi
else
  bash "$HOME/.claude/hooks/slack-team-progress.sh" "$TEAM" "complete" "${PART} 파트 분석 완료 (결과 파일 미생성 — 수동 확인 필요)" >/dev/null
fi
