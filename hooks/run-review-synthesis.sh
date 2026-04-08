#!/usr/bin/env bash
# 독립 세션으로 종합 판정을 실행합니다.
# 사용법: bash run-review-synthesis.sh <team> <reviewer-agent> <subject-file> <output-dir> <part1> <part2> <part3>
#
# 예시:
#   bash run-review-synthesis.sh "review-team" "team-reviewer" "/tmp/review/subject.md" "/tmp/review" "UX" "Tech" "Risk"
#
# 3개 파트의 결론을 종합하여 최종 판정을 내리고,
# 결과를 <output-dir>/synthesis.md에 저장합니다.
#
# Slack 스레드:
#   SLACK_BOT_TOKEN 설정 시, "Phase 2 시작" 메시지의 스레드에 판정 내용이,
#   "전체 리뷰 완료" 메시지의 스레드에 종합 판정 결과가 자동으로 게시됩니다.

set -euo pipefail

TEAM="${1:?team required}"
REVIEWER="${2:?reviewer agent required}"
SUBJECT_FILE="${3:?subject file required}"
OUTPUT_DIR="${4:?output dir required}"
PART1="${5:?part1 name required}"
PART2="${6:?part2 name required}"
PART3="${7:?part3 name required}"

# 분석 대상 읽기
SUBJECT=$(cat "$SUBJECT_FILE" 2>/dev/null)

# 3개 파트 결과 읽기
RESULT1=$(cat "$OUTPUT_DIR/${PART1}.md" 2>/dev/null || echo "(${PART1} 파트 결과 없음)")
RESULT2=$(cat "$OUTPUT_DIR/${PART2}.md" 2>/dev/null || echo "(${PART2} 파트 결과 없음)")
RESULT3=$(cat "$OUTPUT_DIR/${PART3}.md" 2>/dev/null || echo "(${PART3} 파트 결과 없음)")

# Phase 2 시작 알림 (ts 캡처하여 스레드 활용)
START_TS=$(bash "$HOME/.claude/hooks/slack-team-progress.sh" "$TEAM" "start" "Phase 2 시작 — 종합 판정")

# SLACK_THREAD_TS를 export하면 claude -p 세션의 훅들이 스레드로 전송
export SLACK_THREAD_TS="${START_TS:-}"

# 프롬프트 구성
read -r -d '' PROMPT <<ENDPROMPT || true
너는 ${TEAM}의 종합 판정 오케스트레이터다.

## 분석 대상
${SUBJECT}

## 3개 파트 토론 최종 결론

### ${PART1} 파트 최종 결론
${RESULT1}

---

### ${PART2} 파트 최종 결론
${RESULT2}

---

### ${PART3} 파트 최종 결론
${RESULT3}

## 수행 절차

Agent 도구로 ${REVIEWER} 에이전트(subagent_type="${REVIEWER}")를 실행한다.
프롬프트에 다음을 포함한다:
- 분석 대상 전문
- 위 3개 파트 최종 결론 전문
- "종합 판정을 수행해주세요. 3개 파트의 결론을 종합하여 충돌을 조율하고 최종 판정을 내려주세요"

${REVIEWER}의 응답 전문을 Write 도구로 다음 파일에 저장한다:
${OUTPUT_DIR}/synthesis.md

## 중요 규칙
- 프롬프트에 '종합 판정'을 명시할 것 (Slack 훅이 자동 추출함)
- Agent 도구만 사용하고 코드 작성/수정은 하지 말 것
- 에이전트 응답을 요약하지 말고 전문을 저장할 것
ENDPROMPT

# claude -p 세션 실행 (cmux 래퍼 우회하여 settings.json 훅 직접 로드)
CMUX_CLAUDE_HOOKS_DISABLED=1 claude -p "$PROMPT" --output-format text 2>/dev/null || true

# 스레드 해제 (완료 메시지는 독립 메시지로 전송)
unset SLACK_THREAD_TS

# 완료 알림
if [ -f "$OUTPUT_DIR/synthesis.md" ]; then
  FINISH_TS=$(bash "$HOME/.claude/hooks/slack-team-progress.sh" "$TEAM" "finish" "전체 리뷰 완료 — 종합 판정 보고서 제출")

  # 완료 메시지의 스레드에 종합 판정 결과 게시
  if [ -n "$FINISH_TS" ]; then
    cat "$OUTPUT_DIR/synthesis.md" | bash "$HOME/.claude/hooks/slack-team-notify.sh" \
      "$REVIEWER" ":memo: 종합 판정 결과" "" "$TEAM" "$FINISH_TS" >/dev/null
  fi
else
  bash "$HOME/.claude/hooks/slack-team-progress.sh" "$TEAM" "finish" "종합 판정 완료 (결과 파일 미생성 — 수동 확인 필요)" >/dev/null
fi
