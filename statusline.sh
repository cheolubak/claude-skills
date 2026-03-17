#!/bin/bash
# Claude Code status line script
# Reads JSON from stdin and outputs a formatted status line

input=$(cat)

# ANSI color codes (using $'...' so escape chars are real)
RST=$'\033[0m'
BLUE=$'\033[0;34m'
CYAN=$'\033[0;36m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[0;33m'
RED=$'\033[0;31m'
MAGENTA=$'\033[0;35m'
DIM=$'\033[2m'

# Extract fields
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
model=$(echo "$input" | jq -r '.model.display_name // ""')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
session_name=$(echo "$input" | jq -r '.session_name // empty')
remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // 0' | cut -d. -f1)

# Shorten path: replace $HOME with ~
short_cwd="${cwd/#$HOME/~}"

# Build git branch info
branch=""
if git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
  branch=$(git -C "$cwd" -c core.fsmonitor=false symbolic-ref --short HEAD 2>/dev/null)
  if [ -n "$branch" ]; then
    branch=" ${CYAN}[${branch}]${RST}"
  fi
fi

# Context usage indicator
ctx_info=""
if [ -n "$used_pct" ]; then
  used_int=${used_pct%.*}
  if [ "$used_int" -ge 80 ] 2>/dev/null; then
    ctx_info=" ${RED}${used_pct}%${RST}"
  elif [ "$used_int" -ge 50 ] 2>/dev/null; then
    ctx_info=" ${YELLOW}${used_pct}%${RST}"
  else
    ctx_info=" ${GREEN}${used_pct}%${RST}"
  fi
fi

# Session name indicator
sess_info=""
if [ -n "$session_name" ]; then
  sess_info=" ${MAGENTA}\"${session_name}\"${RST}"
fi

# Remaining indicator with color
remain_info=""
if [ -n "$remaining" ] && [ "$remaining" -gt 0 ] 2>/dev/null; then
  if [ "$remaining" -le 20 ]; then
    remain_info=" ${RED}${remaining}% remaining${RST}"
  elif [ "$remaining" -le 50 ]; then
    remain_info=" ${YELLOW}${remaining}% remaining${RST}"
  else
    remain_info=" ${GREEN}${remaining}% remaining${RST}"
  fi
fi

printf "%s" "${BLUE}${short_cwd}${RST}${branch} ${DIM}${model}${RST}${ctx_info}${sess_info}${remain_info}"
echo
