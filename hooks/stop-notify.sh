#!/usr/bin/env bash
# Hook: Stop
# 세션 종료 시 Claude 작업 요약 + git 컨텍스트를 Slack으로 전달
# stdin: Claude Code가 전달하는 JSON (last_assistant_message, cwd 등 포함)

INPUT=$(cat)
[ -z "$INPUT" ] && INPUT='{}'

WORK_DIR=$(echo "$INPUT" | jq -r '.cwd // empty')
WORK_DIR="${WORK_DIR:-${CLAUDE_WORKING_DIRECTORY:-$(pwd)}}"
SLACK_CHANNEL_ID="${SLACK_CHANNEL_ID:-}"

project_name=$(basename "$WORK_DIR")

# --- 사용자 요청 메시지 추출 (transcript에서) ---
transcript_path=$(echo "$INPUT" | jq -r '.transcript_path // empty')
user_request=""
if [ -n "$transcript_path" ] && [ -f "$transcript_path" ]; then
  # 마지막 실제 사용자 메시지 추출 (시스템/커맨드 메시지 제외)
  user_request=$(jq -r '
    select(.type == "user" and .userType == "external")
    | .message.content
    | select(test("^<(local-command|command-name)") | not)
  ' "$transcript_path" 2>/dev/null | tail -1)

  # 너무 길면 잘라냄 (200자)
  if [ ${#user_request} -gt 200 ]; then
    user_request="${user_request:0:200}…"
  fi
fi

# --- Claude 작업 요약 추출 ---
last_message=$(echo "$INPUT" | jq -r '.last_assistant_message // empty')

# Markdown → Slack mrkdwn 기본 변환
md_to_slack() {
  sed \
    -e 's/^#### \(.*\)/*\1*/' \
    -e 's/^### \(.*\)/*\1*/' \
    -e 's/^## \(.*\)/*\1*/' \
    -e 's/^# \(.*\)/*\1*/' \
    -e 's/\*\*\([^*]*\)\*\*/*\1*/g'
}

# --- Git 기반 상세 요약 (last_message 없을 때 fallback) ---
build_git_summary() {
  local summary=""
  local NL=$'\n'

  cd "$WORK_DIR" 2>/dev/null || return
  git rev-parse --is-inside-work-tree &>/dev/null || return

  local branch
  branch=$(git branch --show-current 2>/dev/null)

  local recent_commits
  recent_commits=$(git log --oneline --since="2 hours ago" 2>/dev/null | head -10)

  local diff_stat
  diff_stat=$(git diff --stat 2>/dev/null | tail -1)
  local staged_stat
  staged_stat=$(git diff --cached --stat 2>/dev/null | tail -1)

  local changed_files
  changed_files=$(git diff --name-only 2>/dev/null)
  local staged_files
  staged_files=$(git diff --cached --name-only 2>/dev/null)
  local untracked_files
  untracked_files=$(git ls-files --others --exclude-standard 2>/dev/null)
  local all_files
  all_files=$(printf '%s\n%s\n%s' "$changed_files" "$staged_files" "$untracked_files" | sort -u | sed '/^$/d')

  if [ -n "$branch" ]; then
    summary+=":git: \`${branch}\`${NL}"
  fi

  if [ -n "$recent_commits" ]; then
    local commit_count
    commit_count=$(echo "$recent_commits" | wc -l | tr -d ' ')
    summary+="${NL}*커밋 ${commit_count}건:*${NL}"
    while IFS= read -r line; do
      summary+="  • \`${line}\`${NL}"
    done <<< "$recent_commits"
  fi

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

    if [ -n "$diff_stat" ] && [[ "$diff_stat" == *"changed"* ]]; then
      summary+="${NL}_${diff_stat}_${NL}"
    fi
    if [ -n "$staged_stat" ] && [[ "$staged_stat" == *"changed"* ]]; then
      summary+="_staged: ${staged_stat}_${NL}"
    fi
  fi

  if [ -z "$recent_commits" ] && [ -z "$all_files" ]; then
    summary+="${NL}변경 사항 없음"
  fi

  echo "$summary"
}

# --- Git 컨텍스트 상세 ---
build_git_context() {
  cd "$WORK_DIR" 2>/dev/null || return
  git rev-parse --is-inside-work-tree &>/dev/null || return

  local ctx=""
  local NL=$'\n'
  local branch
  branch=$(git branch --show-current 2>/dev/null)
  [ -n "$branch" ] && ctx+=":git: \`${branch}\`${NL}"

  # 최근 커밋 메시지 상세
  local recent_commits
  recent_commits=$(git log --oneline --since="2 hours ago" 2>/dev/null | head -10)
  if [ -n "$recent_commits" ]; then
    ctx+="${NL}*커밋:*${NL}"
    while IFS= read -r line; do
      ctx+="  • \`${line}\`${NL}"
    done <<< "$recent_commits"
  fi

  # 미커밋 변경 파일명 상세
  local all_files
  all_files=$(printf '%s\n%s\n%s' \
    "$(git diff --name-only 2>/dev/null)" \
    "$(git diff --cached --name-only 2>/dev/null)" \
    "$(git ls-files --others --exclude-standard 2>/dev/null)" | sort -u | sed '/^$/d')
  if [ -n "$all_files" ]; then
    ctx+="${NL}*미커밋 변경:*${NL}"
    local shown=0
    while IFS= read -r f && [ $shown -lt 15 ]; do
      ctx+="  • \`$f\`${NL}"
      ((shown++))
    done <<< "$all_files"
    local total
    total=$(echo "$all_files" | wc -l | tr -d ' ')
    local remaining=$((total - shown))
    if [ $remaining -gt 0 ]; then
      ctx+="  _...외 ${remaining}개_${NL}"
    fi
  fi

  echo "$ctx"
}

# --- 시스템 알림용 짧은 메시지 ---
short_msg="작업 완료"

# --- notify.sh로 전달 ---
if [ -n "$SLACK_CHANNEL_ID" ]; then
  # 작업 요약: last_assistant_message 우선, 없으면 git 기반 요약
  if [ -n "$last_message" ]; then
    summary=$(echo "$last_message" | md_to_slack)
  else
    summary=$(build_git_summary)
  fi

  # Slack section block 텍스트 제한 (3000자)
  if [ ${#summary} -gt 2900 ]; then
    summary="${summary:0:2900}…"
  fi

  git_ctx=$(build_git_context)

  # Block Kit 구성
  blocks='[]'

  # 1. 헤더: 멘션 + 프로젝트명
  blocks=$(echo "$blocks" | jq \
    --arg mention "<@${SLACK_CHANNEL_ID}>" \
    --arg project "$project_name" \
    '. + [{type:"section",text:{type:"mrkdwn",text:($mention + " :white_check_mark: *" + $project + "* 작업 완료")}}]')

  # 2. 사용자 요청 메시지
  if [ -n "$user_request" ]; then
    blocks=$(echo "$blocks" | jq --arg r ":speech_balloon: *요청:* $user_request" \
      '. + [{type:"section",text:{type:"mrkdwn",text:$r}}]')
  fi

  # 3. 구분선 + 작업 요약
  if [ -n "$summary" ]; then
    blocks=$(echo "$blocks" | jq --arg s "$summary" \
      '. + [{type:"divider"}, {type:"section",text:{type:"mrkdwn",text:$s}}]')
  fi

  # 4. Git 컨텍스트 상세
  if [ -n "$git_ctx" ]; then
    blocks=$(echo "$blocks" | jq --arg c "$git_ctx" \
      '. + [{type:"divider"}, {type:"section",text:{type:"mrkdwn",text:$c}}]')
  fi

  jq -n \
    --arg title "Claude Code - ${project_name}" \
    --arg message "$short_msg" \
    --argjson blocks "$blocks" \
    '{title: $title, message: $message, blocks: $blocks}' | bash "$HOME/.claude/notify.sh"
else
  # Slack 미설정 → plain text
  jq -n \
    --arg title "Claude Code - ${project_name}" \
    --arg message "$short_msg" \
    '{title: $title, message: $message}' | bash "$HOME/.claude/notify.sh"
fi
