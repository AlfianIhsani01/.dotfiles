#!/data/data/com.termux/files/usr/bin/env sh
extract() {
   if [ -f "$1" ]; then
      case "$1" in
      *.tar.bz2) tar -jxvf "$1" ;;
      *.tar.gz) tar -zxvf "$1" ;;
      *.bz2) bunzip2 "$1" ;;
      *.dmg) hdiutil mount "$1" ;;
      *.gz) gunzip "$1" ;;
      *.tar) tar -xvf "$1" ;;
      *.tbz2) tar -jxvf "$1" ;;
      *.tgz) tar -zxvf "$1" ;;
      *.zip) unzip "$1" ;;
      *.ZIP) unzip "$1" ;;
      *.pax) cat "$1" | pax -r ;;
      *.pax.Z) uncompress "$1" --stdout | pax -r ;;
      *.rar) unrar x "$1" ;;
      *.Z) uncompress "$1" ;;
      *.7z) 7zx "$1" ;;
      *) echo "'$1' cannot be extracted/mounted via extract()" ;;
      esac
   else
      echo "'$1' is not a valid file"
   fi
}

cd() {
   if test -n "$1"; then
      builtin cd "$1" && ls || return 0
   else
      builtin cd "$HOME" && ls || return 0
   fi
}

mkd() {
   mkdir -p "$@" && test "$#" -le "1" && builtin cd "$1" || return 0
}

# Easy go to config
cfg() {
   folder="$1"
   config_path=${XDG_CONFIG_HOME:-$HOME/.config}
   if test -d "$config_path/$folder"; then
      cd "$config_path/$folder" || return 0
   else
      cd "$config_path" || return 0
   fi
   unset -v folder config_path
}

# Move and go to the directory
mvg() {
   if test -d "$2"; then
      mv "$1" "$2" && cd "$2" || return 0
   else
      mv "$1" "$2"
   fi
}

# fzf
__orintation() {
   row=$(stty size | awk '{print $1}')
   col=$(stty size | awk '{s=$2/2} END {print s}')

   if test "$(echo "$row >= $col" | bc -l)"; then
      echo "--preview-window=up"
   else
      echo "--preview-window=right"
   fi
   unset -v row col
}

fvi() {
   file=$(
      FZF_DEFAULT_COMMAND="fd --follow -tf"
      fzf --preview "bat --style=plain --color=always {}"
   )
   test -n "${file}" && "${EDITOR}" "${file}"
   unset file
}

fcd() {
   dir=$(
      FZF_DEFAULT_COMMAND="fd --follow -td --hidden -E .git"
      fzf --preview="if [ -d {} ]; then ls --color=always -A {}; else bat {}; fi" | xargs -r -I {} echo {}
   )
   test -d "$dir" && cd "$dir" || return 0
   unset dir
}

pkgi() {
   window=$(__orintation)
   package=$(
      FZF_DEFAULT_OPTS="--exact --style=full"
      FZF_DEFAULT_COMMAND="pkg list-all | awk '{print \$1 \" \" \$2}' | bat -r 2:"
      fzf --preview "echo {} | \
         awk -F/ '{print \$1}' | \
         xargs pkg show 2>/dev/null" "${window}" |
         awk -F/ '{print $1}'
   )

   test -n "${package}" &&
      echo "installing ${package}..." &&
      pkg install "${package}" &&
      unset -v window package ||
      return 0
}

todo() {
   package=$(
      FZF_DEFAULT_OPTS="--exact"
      FZF_DEFAULT_COMMAND="rg"
      fzf --preview "
         awk -F: '{print \$1}' |
         xargs cat 2>/dev/null" "${window}"
   )
   unset package
}

fgrep() {
   dir="${1:-.}"
   initial_query="${2:-}"
   window=$(__orintation)
   # Use rg (ripgrep) if available, otherwise fall back to grep
   if command -v rg 2>/dev/null; then
      SEARCH_CMD="rg --color=always --colors match:none --line-number --no-heading --trim --smart-case"
   else
      SEARCH_CMD="grep -r --color=always --line-number"
   fi

   # Interactive search with live reloading
   selected=$(
      FZF_DEFAULT_OPTS="--exact"
      FZF_DEFAULT_COMMAND="$SEARCH_CMD '\S' '$dir'"
      fzf --ansi \
         --disabled \
         --bind "change:reload:$SEARCH_CMD {q} '$dir' || true" \
         --bind "enter:become(echo {1}:{2})" \
         --preview 'bat --number --color=always --line-range {2}::60 --highlight-line {2} {1} 2>/dev/null || cat {1}' \
         "${window}" \
         --delimiter ':' \
         --prompt '> ' \
         --header 'Type to search • Enter to open • Ctrl-C to cancel' \
         --query "$initial_query"
   )

   # Open the selected file in editor if one was chosen
   if [ -n "$selected" ]; then
      file=$(echo "$selected" | cut -d: -f1)
      line=$(echo "$selected" | cut -d: -f2)
      ${EDITOR:-vim} "+$line" "$file"
      unset -v line file
   fi
   unset -v selected dir initial_query window
}

# ALIAS
# ▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔
alias ssha='eval $(ssh-agent -s) && ssh-add'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias c='clear'

# Alias's for multiple directory listing commands
test "$(command -v eza 2>/dev/null)" && alias ls='eza --color=always --icons' # add colors and file type extensions
alias l='ls -ah -F auto'
alias la='ls -Alh'               # show hidden files
alias lx='ls -lXBh'              # sort by extension
alias lk='ls -lSrh'              # sort by size
alias lc='ls -ltcrh'             # sort by change time
alias lu='ls -lturh'             # sort by access time
alias lr='ls -lRh'               # recursive ls
alias lt='ls -ltrh'              # sort by date
alias lm='ls -alh |more'         # pipe through 'more'
alias lw='ls -xAh'               # wide listing format
alias ll='ls -l -s size -F auto' # long listing format
alias labc='ls -lap'             # alphabetical sort
alias lf='ls -lf | rg -v '^d''   # files only
alias ldir='ls -l | rg '^d''     # directories only
alias lla='ls -Al'               # List and Hidden Files
alias las='ls -A'                # Hidden Files
alias lls='ls -l'                # List

alias g='git'
alias v='$EDITOR'
alias vi='$EDITOR'
alias k='kak'
