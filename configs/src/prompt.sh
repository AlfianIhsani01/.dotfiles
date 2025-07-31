#!/data/data/com.termux/files/usr/bin/env bash

# Color codes
declare -r RED='\[\033[0;31m\]'
declare -r GREEN='\[\033[0;32m\]'
declare -r YELLOW='\[\033[0;33m\]'
declare -r BLUE='\[\033[0;34m\]'
declare -r PURPLE='\[\033[0;35m\]'
declare -r CYAN='\[\033[0;36m\]'
declare -r WHITE='\[\033[0;37m\]'
declare -r RESET='\[\033[0m\]'
declare -r BOLD='\[\033[1m\]'

# fill() {
#   local TERM_COLUMN=$(stty size | awk '{print $NF}')
#   for ((i = 0; i < "$TERM_COLUMN"; i++)); do
#     printf "₋"
#   done
# }

main_prompt() {
  # local exit_code=$?
  if [ $? -eq 0 ]; then
    local STATUS_COLOR=$GREEN
  else
    local STATUS_COLOR=$RED
  fi

  # Choose color based on exit status
  local USER=$(if [[ $(id -un) != "root" ]]; then
    echo "akal"
  fi)
  local BRANCH=$(git branch --show-current 2>/dev/null)
  local IC=$(if [[ ! $BRANCH ]]; then
    echo "${PURPLE}${BOLD}‒${RESET}"
  else
    echo "${CYAN}‒${WHITE}${BRANCH}${CYAN}‒"
  fi)
  # Build the prompt
  PS1="\
${YELLOW}▌${USER}${RESET} ›${BLUE}\h${RESET}:\
${GREEN}\w${RESET}
${IC}${STATUS_COLOR}❯${RESET} "
}

# Set the prompt command to run our function before each prompt
PROMPT_COMMAND=main_prompt

# Alternative minimal version (uncomment to use instead):
# PROMPT_COMMAND='PS1="\[\033[0;$((31+!$?))m\]\u@\h:\w\$ \[\033[0m\]"'
