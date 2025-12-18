#!/bin/env bash

ENABLE_PROMPT=true

export PROMPT_DIRTRIM=3
export PS2="▌"

_PROMPT_USER="${USER:-$(id -un)}"
case "$_PROMPT_USER" in
u0_*) _PROMPT_USER="▌akal " ;;
esac

case "$_PROMPT_USER" in
root) _PROMPT_USER_COLOR=0 ;;
*) _PROMPT_USER_COLOR=3 ;;
esac

# Color array (POSIX-compatible)
_C0="$(printf '\[\e[31m\]')" # Red
_C1="$(printf '\[\e[32m\]')" # Green
_C2="$(printf '\[\e[33m\]')" # Yellow
_C3="$(printf '\[\e[34m\]')" # Blue
_C4="$(printf '\[\e[35m\]')" # Magenta
_C5="$(printf '\[\e[36m\]')" # Cyan
_C6="$(printf '\[\e[37m\]')" # White
_C7="$(printf '\[\e[0m\]')"  # Reset

fill() {
   e=$(sed 's/..\[[0-9;]*m.//g' <<<"${1@P}")
   for ((i = 1; i <= COLUMNS - ${#e}; i++)); do
      printf "─"
   done
   echo "${1@P}"
   unset -v prompt e fill
}

git_status() {
   bits=""
   status=$(git status --porcelain=v1 --branch 2>/dev/null) || return 0
   while IFS= read -r line; do
      case $line in
      "## " | *" [ahead "*) [[ "$bits" != *"*"* ]] && bits="*$bits" ;;
      [RC]" "*) [[ "$bits" != *">"* ]] && bits=">$bits" ;;
      *[M]* | *" M") [[ "$bits" != *"!"* ]] && bits="!$bits" ;;
      *[D]* | *" D") [[ "$bits" != *"x"* ]] && bits="x$bits" ;;
      [A]" "* | *" A") [[ "$bits" != *"+"* ]] && bits="+$bits" ;;
      "??"*) [[ "$bits" != *"?"* ]] && bits="?$bits" ;;
      esac
   done <<<"$status"

   test -n "$bits" && echo " ${_C4}[$_C6${bits:-${#bits}}$_C4]$_C6"
   unset -v status bits
}

main_prompt() {
   exit_code=$?
   test "$exit_code" -eq 0 &&
      exit_color="$_C5" ||
      exit_color="$_C0"

   jobs=""
   test -n "$(jobs)" &&
      jobs=" ◙"
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
   PS1="\n\r\[\e[2m\]$_C3$(fill "$_C7$(git_status)$_C2${jobs}")\r$user_color${_PROMPT_USER}$_C7› $_C2\w \n\
$_C3${branch}$exit_color❯ $_C7"

   unset -v branch branch_name exit_color user_color jobs
}

# Set up prompt command
if [ -n "$BASH_VERSION" ] || [ -n "$ZSH_VERSION" ] && [ "$ENABLE_PROMPT" == true ]; then
   PROMPT_COMMAND=main_prompt
elif [ "$ENABLE_PROMPT" == true ]; then
   # For other POSIX shells, set initial prompt and update on cd
   main_prompt
   if command -v cd >/dev/null 2>&1; then
      cd() {
         command cd "$@" && main_prompt
      }
   fi
fi
unset -v \
   ENABLE_PROMPT \
   _PROMPT_USER
