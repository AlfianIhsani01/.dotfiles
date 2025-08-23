#!/bin/env bash
export PROMPT_DIRTRIM=3

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

# Pre-compute static values to avoid repeated calls
_PROMPT_USER="${USER:-$(id -un)}"
case "$_PROMPT_USER" in
    u0_*) _PROMPT_USER="akal" ;;
esac

case "$_PROMPT_USER" in
    root) _PROMPT_USER_COLOR=0 ;;
    *) _PROMPT_USER_COLOR=3 ;;
esac

# Color array (POSIX-compatible)
_C0="$(printf '\033[31m')"  # Red         
_C1="$(printf '\033[32m')"  # Green
_C2="$(printf '\033[33m')"  # Yellow
_C3="$(printf '\033[34m')"  # Blue
_C4="$(printf '\033[35m')"  # Magenta
_C5="$(printf '\033[36m')"  # Cyan
_C6="$(printf '\033[37m')"  # White
_C7="$(printf '\033[0m')"   # Reset

main_prompt() {
    exit_code=$?
    
    # Fast exit code color selection
    if [ "$exit_code" -eq 0 ]; then
        exit_color="$_C5"
    else
        exit_color="$_C0"
    fi
    
    # Get git branch only if in a git repository
    # Use a single git command for better performance
    branch=""
    if git rev-parse --git-dir >/dev/null 2>&1; then
        branch_name="$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)"
        if [ -n "$branch_name" ]; then
            branch="▌$branch_name "
        fi
    fi
    
    # Get user color based on pre-computed value
    case "$_PROMPT_USER_COLOR" in
        0) user_color="$_C0" ;;
        3) user_color="$_C3" ;;
    esac
    
    # Build prompt in one assignment for efficiency
    PS1="${user_color}▌${_PROMPT_USER}${_C7} › ${_C2}\w
${_C4}${branch}${exit_color}❯ ${_C7}"
}

# Set up prompt command
if [ -n "$BASH_VERSION" ] || [ -n "$ZSH_VERSION" ]; then
    PROMPT_COMMAND=main_prompt
else
    # For other POSIX shells, set initial prompt and update on cd
    main_prompt
    if command -v cd >/dev/null 2>&1; then
        cd() {
            command cd "$@" && main_prompt
        }
    fi
fi

# Alternative ultra-fast version without git branch (uncomment to use):
# main_prompt() {
#     case "$?" in
#         0) s="$_C5" ;;
#         *) s="$_C0" ;;
#     esac
#     case "$_PROMPT_USER_COLOR" in
#         0) u="$_C0" ;;
#         3) u="$_C3" ;;
#     esac
#     PS1="${u}▌${_PROMPT_USER}${_C7} › ${_C2}\w
# ${s}❯ ${_C7}"
# }
