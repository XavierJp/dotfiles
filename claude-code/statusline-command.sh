#!/bin/bash
# Claude Code statusline, adapted from the "arrow-custom" oh-my-zsh theme
# (~/.oh-my-zsh/custom/themes/arrow-custom.zsh-theme) used in ~/.zshrc.

input=$(cat)

cwd=$(printf '%s' "$input" | jq -r '.workspace.current_dir')
model=$(printf '%s' "$input" | jq -r '.model.display_name')

ESC=$'\033'
RESET="${ESC}[0m"
WHITE="${ESC}[37m"
DIRTY="${ESC}[38;5;208m"
GREEN="${ESC}[32m"
RED="${ESC}[31m"
CYAN="${ESC}[36m"
ORANGE="${ESC}[38;5;214m"
BLUE="${ESC}[38;5;77m"
DIM="${ESC}[2m"

dir_display=$(basename "$cwd")

git_segment=""
if git -C "$cwd" --no-optional-locks rev-parse --is-inside-work-tree &>/dev/null; then
  ref=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)
  if [ -n "$ref" ]; then
    dirty=""
    [ -n "$(git -C "$cwd" --no-optional-locks status --porcelain 2>/dev/null)" ] && dirty="${DIRTY}*${RESET}"

    ab=""
    ahead_behind=$(git -C "$cwd" --no-optional-locks rev-list --left-right --count HEAD...@{upstream} 2>/dev/null)
    if [ -n "$ahead_behind" ]; then
      ahead=$(echo "$ahead_behind" | awk '{print $1}')
      behind=$(echo "$ahead_behind" | awk '{print $2}')
      [ "$ahead" -gt 0 ] 2>/dev/null && ab="${ab} ${GREEN}^${ahead}${RESET}"
      [ "$behind" -gt 0 ] 2>/dev/null && ab="${ab} ${RED}v${behind}${RESET}"
    fi

    stash_count=$(git -C "$cwd" --no-optional-locks stash list 2>/dev/null | wc -l | tr -d ' ')
    stash=""
    [ "$stash_count" -gt 0 ] 2>/dev/null && stash=" ${CYAN}(stash:${stash_count})${RESET}"

    git_segment=" ${WHITE}${ref}${RESET}${dirty}${ab}${stash}"
  fi
fi

python_segment=""
if [ -f "$cwd/pyproject.toml" ]; then
  py_version=$(grep -E '^requires-python' "$cwd/pyproject.toml" 2>/dev/null | sed -E 's/.*[">= ]+([0-9]+\.[0-9]+).*/\1/')
  if [ -z "$py_version" ] && [ -f "$cwd/.python-version" ]; then
    py_version=$(head -1 "$cwd/.python-version")
  fi
  [ -n "$py_version" ] && python_segment=" ${ORANGE}py:${py_version}${RESET}"
fi

node_segment=""
if [ -f "$cwd/package.json" ]; then
  node_version=$(node --version 2>/dev/null)
  [ -n "$node_version" ] && node_segment=" ${BLUE}node:${node_version}${RESET}"
fi

line="${DIM}${WHITE}${dir_display}${RESET}${git_segment}${python_segment}${node_segment} ${DIM}(${model})${RESET}"

printf "%s\n" "$line"
