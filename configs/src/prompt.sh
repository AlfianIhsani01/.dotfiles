#!/bin/env bash
export PROMPT_DIRTRIM=3
# Color codes
declare -rA COLOR=(
[0]='\[\033[0;31m\]' # red
[1]='\[\033[0;32m\]' # green
[2]='\[\033[0;33m\]' # yellow
[3]='\[\033[0;34m\]' # blue
[4]='\[\033[6;35m\]' # purple
[5]='\[\033[0;36m\]' # cyan
[6]='\[\033[0;38m\]' # white
[7]='\[\033[0m\]'    # reset
[8]='\[\033[1m\]'    # bold
)

function git_status {
  local status bits=""

  # Use porcelain format - faster and more reliable than parsing human output
  status=$(git status --porcelain=v1 --branch 2>/dev/null) || return

  # Single pass through status checking for patterns
  while IFS= read -r line; do
    case $line in
    "## "*" [ahead "*) [[ $bits != *"*"* ]] && bits="*${bits}" ;;
    [MARC]" "*) [[ $bits != *">"* ]] && bits=">${bits}" ;;          # renamed/moved
    *[M]* | *" M") [[ $bits != *"!"* ]] && bits="!${bits}" ;;       # modified
    [AD]" "* | *" "[AD]) [[ $bits != *"x"* ]] && bits="x${bits}" ;; # deleted
    "A "* | " A"*) [[ $bits != *"+"* ]] && bits="+${bits}" ;;       # added
    "??"*) [[ $bits != *"?"* ]] && bits="?${bits}" ;;               # untracked
    esac
  done <<<"$status"

  [[ -n $bits ]] && echo " ${bits}"
}

function main_prompt() {

  local exit_code=$?
  local s=5
  if [ $exit_code -ne 0 ]; then
    s=$((s - 5))
  fi

  local USER
  USER=$(id -un)
  local u=3
  USER=$(if [[ $USER == u0_* ]]; then
           echo "akal"
         elif [[ $USER == root ]]; then
           echo "$USER"
           u=$((u - 3))
         else
           echo "$USER"
         fi)
  # local JOBS;
  # JOBS=$([ "$(jobs)" != "" ] && echo "\j")

  local BRANCH
  BRANCH=$(git branch --show-current 2>/dev/null | sed 's/^/▌/;s/$/ /')

  PS1="\
${COLOR[$u]}▌${USER}${COLOR[7]} › \
${COLOR[2]}\w
${COLOR[4]}${BRANCH}${COLOR[$s]}❯ ${COLOR[7]}" 
}

PROMPT_COMMAND=main_prompt
