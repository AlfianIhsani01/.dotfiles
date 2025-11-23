#!/bin/env sh

ENABLE_PROMPT="false"
export PROMPT_DIRTRIM=3
export PS2="▌"

git_status() {
   status bits=""
   # Use porcelain format - faster and more reliable than parsing human output
   status=$(git status --porcelain=v1 --branch 2>/dev/null) || return
   # Single pass through status checking for patterns
   while IFS= read -r line; do
      case $line in
      "## "*" [ahead "*) test "$bits" != *"*"* && bits="*${bits}" ;;
      [MARC]" "*) test "$bits" != *">"* && bits=">${bits}" ;;          # renamed/moved
      *[M]* | *" M") test "$bits" != *"!"* && bits="!${bits}" ;;       # modified
      [AD]" "* | *" "[AD]) test "$bits" != *"x"* && bits="x${bits}" ;; # deleted
      "A "* | " A"*) test "$bits" != *"+"* && bits="+${bits}" ;;       # added
      "??"*) test "$bits" != *"?"* && bits="?${bits}" ;;               # untracked
      esac
   done <<<"$status"

   test -n "$bits" && echo " ${bits}"
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
_C0="$(printf '\033[31m')" # Red
_C1="$(printf '\033[32m')" # Green
_C2="$(printf '\033[33m')" # Yellow
_C3="$(printf '\033[34m')" # Blue
_C4="$(printf '\033[35m')" # Magenta
_C5="$(printf '\033[36m')" # Cyan
_C6="$(printf '\033[37m')" # White
_C7="$(printf '\033[0m')"  # Reset

main_prompt() {
   exit_code=$?

   # Fast exit code color selection
   if [ "$exit_code" -eq 0 ]; then
      exit_color="$_C5"
   else
      exit_color="$_C0"
   fi

   jobs=""
   if [ -n "$(jobs)" ]; then
      jobs="${_C1} ●"
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
   export PS1
PS1="\n${user_color}▌${_PROMPT_USER}${_C7} › ${_C2}\w${_C7}$(git_status)${jobs}
${_C4}${branch}${exit_color}\a❯ ${_C7}"
}

# Set up prompt command
if [ -n "$BASH_VERSION" ] || [ -n "$ZSH_VERSION" ] && [ "$ENABLE_PROMPT" == "true" ]; then
   PROMPT_COMMAND=main_prompt
elif [ "$ENABLE_PROMPT" == "true" ]; then
   # For other POSIX shells, set initial prompt and update on cd
   main_prompt
   if command -v cd >/dev/null 2>&1; then
      cd() {
         command cd "$@" && main_prompt
      }
   fi
fi
unset -v ENABLE_PROMPT
