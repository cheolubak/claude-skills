#!/usr/bin/env bash
# 독립 세션으로 토론 파트를 실행합니다.
# 사용법: bash run-review-part.sh <team> <part> <primary-agent> <secondary-agent> <subject-file> <output-dir>
#
# 예시:
#   bash run-review-part.sh "review-team" "UX" "ux-expert" "ux-researcher" "/tmp/review/subject.md" "/tmp/review"
#
# 각 파트는 독립된 claude -p 세션에서 3라운드 토론을 수행하고,
# 최종 결론을 <output-dir>/<part>.md에 저장합니다.

set -euo pipefail

TEAM="${1:?team required}"
PART="${2:?part name required}"
PRIMARY="${3:?primary agent required}"
SECONDARY="${4:?secondary agent required}"
SUBJECT_FILE="${5:?subject file required}"
OUTPUT_DIR="${6:?output dir required}"

# 분석 대상 읽기
SUBJECT=$(cat "$SUBJECT_FILE" 2>/dev/null)
[ -z "$SUBJECT" ] && echo "ERROR: subject file empty" >&2 && exit 1

mkdir -p "$OUTPUT_DIR"

# 시작 알림
bash "$HOME/.claude/hooks/slack-team-progress.sh" "$TEAM" "progress" "${PART} 파트 토론 시작"

# 프롬프트 구성 (heredoc → 변수)
read -r -d '' PROMPT <<ENDPROMPT || true
너는 ${TEAM}의 ${PART} 파트 토론 오케스트레이터다. 코드 작성이 아닌 분석/리서치만 수행한다.

## 분석 대상
${SUBJECT}

## 수행 절차

다음 3라운드 토론을 순서대로 수행한다.

### Round 1 — 초기 분석
Agent 도구로 ${PRIMARY} 에이전트(subagent_type="${PRIMARY}")를 실행한다.
프롬프트에 다음을 포함한다:
- 분석 대상 전문
- "Round 1 초기 분석을 수행해주세요"

Round 1 응답 전문을 기록해둔다.

### Round 2 — 도전/보완
Agent 도구로 ${SECONDARY} 에이전트(subagent_type="${SECONDARY}")를 실행한다.
프롬프트에 다음을 포함한다:
- 분석 대상 전문
- Round 1의 ${PRIMARY} 응답 전문
- "Round 2 도전과 보완을 수행해주세요. Round 1 분석에서 동의/보강할 부분과 도전/보완할 부분을 구분하여 제시해주세요"

Round 2 응답 전문을 기록해둔다.

### Round 3 — 종합 결론
Agent 도구로 ${PRIMARY} 에이전트(subagent_type="${PRIMARY}")를 다시 실행한다.
프롬프트에 다음을 포함한다:
- 분석 대상 전문
- Round 1의 본인 응답 전문
- Round 2의 ${SECONDARY} 응답 전문
- "Round 3 종합 결론을 도출해주세요. Round 2 피드백 중 수용한 것과 수용하지 않은 것을 명시하고, 최종 분석 결론과 핵심 권고사항을 제시해주세요"

### 결과 저장
Round 3의 최종 결론 전문을 Write 도구로 다음 파일에 저장한다:
${OUTPUT_DIR}/${PART}.md

## 중요 규칙
- 각 Round의 Agent 프롬프트에 반드시 'Round N'을 명시할 것 (Slack 훅이 자동 추출함)
- Agent 도구만 사용하고 코드 작성/수정은 하지 말 것
- 3라운드를 모두 완료한 후 반드시 결과 파일을 저장할 것
- 에이전트 응답을 요약하지 말고 전문을 다음 라운드에 전달할 것
ENDPROMPT

# claude -p 세션 실행
claude -p "$PROMPT" --output-format text 2>/dev/null || true

# 결과 파일 확인
if [ -f "$OUTPUT_DIR/${PART}.md" ]; then
  bash "$HOME/.claude/hooks/slack-team-progress.sh" "$TEAM" "complete" "${PART} 파트 토론 완료 (3/3 라운드)"
else
  bash "$HOME/.claude/hooks/slack-team-progress.sh" "$TEAM" "complete" "${PART} 파트 토론 완료 (결과 파일 미생성 — 수동 확인 필요)"
fi
