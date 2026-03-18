#!/usr/bin/env bash
# Hook: Stop
# 세션 종료 시 git 기반 작업 요약을 생성하여 notify.sh로 전달

WORK_DIR="${CLAUDE_WORKING_DIRECTORY:-$(pwd)}"
SLACK_CHANNEL_ID="${SLACK_CHANNEL_ID:-}"

project_name=$(basename "$WORK_DIR")

# --- Git 기반 작업 요약 생성 ---
build_summary() {
  local summary=""
  local NL=$'\n'

  cd "$WORK_DIR" 2>/dev/null || return

  # git 저장소가 아니면 종료
  git rev-parse --is-inside-work-tree &>/dev/null || return

  # 현재 브랜치
  local branch
  branch=$(git branch --show-current 2>/dev/null)

  # 최근 커밋 (2시간 이내)
  local recent_commits
  recent_commits=$(git log --oneline --since="2 hours ago" 2>/dev/null | head -10)

  # 미커밋 변경 통계
  local diff_stat
  diff_stat=$(git diff --stat 2>/dev/null | tail -1)
  local staged_stat
  staged_stat=$(git diff --cached --stat 2>/dev/null | tail -1)

  # 변경된 파일 목록
  local changed_files
  changed_files=$(git diff --name-only 2>/dev/null)
  local staged_files
  staged_files=$(git diff --cached --name-only 2>/dev/null)
  local untracked_files
  untracked_files=$(git ls-files --others --exclude-standard 2>/dev/null)
  local all_files
  all_files=$(printf '%s\n%s\n%s' "$changed_files" "$staged_files" "$untracked_files" | sort -u | sed '/^$/d')

  # 브랜치 정보
  if [ -n "$branch" ]; then
    summary+=":git: \`${branch}\`${NL}"
  fi

  # 커밋 요약
  if [ -n "$recent_commits" ]; then
    local commit_count
    commit_count=$(echo "$recent_commits" | wc -l | tr -d ' ')
    summary+="${NL}*커밋 ${commit_count}건:*${NL}"
    while IFS= read -r line; do
      summary+="  • \`${line}\`${NL}"
    done <<< "$recent_commits"
  fi

  # 미커밋 변경
  if [ -n "$all_files" ]; then
    local file_count
    file_count=$(echo "$all_files" | wc -l | tr -d ' ')
    summary+="${NL}*미커밋 변경 ${file_count}개 파일:*${NL}"

    local shown=0
    while IFS= read -r f && [ $shown -lt 8 ]; do
      summary+="  • \`$f\`${NL}"
      ((shown++))
    done <<< "$all_files"

    local remaining=$((file_count - shown))
    if [ $remaining -gt 0 ]; then
      summary+="  _...외 ${remaining}개_${NL}"
    fi

    # diff 통계 (insertions/deletions)
    if [ -n "$diff_stat" ] && [[ "$diff_stat" == *"changed"* ]]; then
      summary+="${NL}_${diff_stat}_${NL}"
    fi
    if [ -n "$staged_stat" ] && [[ "$staged_stat" == *"changed"* ]]; then
      summary+="_staged: ${staged_stat}_${NL}"
    fi
  fi

  # 아무 변경도 없으면
  if [ -z "$recent_commits" ] && [ -z "$all_files" ]; then
    summary+="${NL}변경 사항 없음"
  fi

  echo "$summary"
}

summary=$(build_summary)

# --- 시스템 알림용 짧은 메시지 ---
short_msg="작업 완료"
if [ -n "$summary" ]; then
  commit_count=$(echo "$summary" | grep -c '• `' || true)
  short_msg="작업 완료 (${commit_count}건 변경)"
fi

# --- notify.sh로 전달 ---
if [ -n "$summary" ] && [ -n "$SLACK_CHANNEL_ID" ]; then
  # Block Kit + 시스템 알림용 title/message 포함
  jq -n \
    --arg title "Claude Code - ${project_name}" \
    --arg message "$short_msg" \
    --arg mention "<@${SLACK_CHANNEL_ID}>" \
    --arg project "$project_name" \
    --arg summary "$summary" \
    '{
      title: $title,
      message: $message,
      blocks: [
        {
          type: "section",
          text: {
            type: "mrkdwn",
            text: ($mention + " :white_check_mark: *" + $project + "* 작업 완료")
          }
        },
        {
          type: "section",
          text: {
            type: "mrkdwn",
            text: $summary
          }
        }
      ]
    }' | bash "$HOME/.claude/notify.sh"
else
  # Slack 미설정 또는 요약 없음 → plain text
  jq -n \
    --arg title "Claude Code - ${project_name}" \
    --arg message "$short_msg" \
    '{title: $title, message: $message}' | bash "$HOME/.claude/notify.sh"
fi
