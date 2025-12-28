#!/bin/env sh

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
_C0="\[\e[31m\]" # Red
_C1="\[\e[32m\]" # Green
_C2="\[\e[33m\]" # Yellow
_C3="\[\e[34m\]" # Blue
_C4="\[\e[35m\]" # Magenta
_C5="\[\e[36m\]" # Cyan
_C6="\[\e[37m\]" # White
_C7="\[\e[0m\]"  # Reset

fill() {
   h=$(echo "$1" | sed 's/\\\[...[0-9;]*m\\\]//g')
   i=0
   j=$((COLUMNS - ${#h}))
   while [ "$i" -lt "$j" ]; do
      printf "─"
      i=$((1 + i))
   done
   echo "$1"
   unset -v prompt h fill i j
}

git_status() {
   status=""
   status=$(git status --porcelain=v1 --branch 2>/dev/null | cut -c2 | sort -u | uniq | tr -d '\n') || return 0
   # test -n "$status" && echo "[$status]"
   test -n "$status" && echo " ${_C4}[$_C6$status$_C4]$_C6"
   unset -v status
}

main_prompt() {
   exit_code=$?
   test "$exit_code" -ne 0 &&
      exit_color="$_C0" ||
      exit_color="$_C5"

   jobs=""
   test -n "$(jobs)" &&
      jobs="$_C0 ◙"

   branch=""
   if git rev-parse --git-dir >/dev/null 2>&1; then
      branch_name="$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)"
      test -n "$branch_name" &&
         branch="▌$branch_name "
   fi

   right_prompt=""
   test -n "$branch_name" || [ -n "$jobs" ] || [ "$0LDPWD" != "$PWD" ] &&
   right_prompt=$(fill "${jobs}$(git_status)")

   # Get user color based on pre-computed value
   case "$_PROMPT_USER_COLOR" in
   0) user_color=$_C0 ;;
   3) user_color=$_C3 ;;
   esac

   # Build prompt in one assignment for efficiency
   export PS1
   PS1="\n\r$_C3${right_prompt}\r$user_color${_PROMPT_USER}$_C7› $_C2\w \n\
$_C3${branch}$exit_color❯ $_C7"
   unset -v branch branch_name exit_color user_color jobs right_prompt
}

# Set up prompt command
if [ -n "$BASH_VERSION" ] || [ -n "$ZSH_VERSION" ] && [ "$ENABLE_PROMPT" = true ]; then
   PROMPT_COMMAND=main_prompt
elif [ "$ENABLE_PROMPT" = true ]; then
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
