#!/bin/env bash
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
    *.pax.Z) uncompress "$1"--stdout | pax -r ;;
    *.rar) unrar x "$1" ;;
    *.Z) uncompress "$1" ;;
    *.7z) 7z x "$1" ;;
    *) echo "'$1' cannot be extracted/mounted via extract()" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

mkd() {
  mkdir -p "$@" && cd "$_" || exit
  return 0
}
# Easy go to config
cfg() {
  folder=$1
  config_path=${XDG_CONFIG_HOME:-$HOME/.config}
  if [ -d "$config_path/$folder" ]; then
    cd "$config_path/$folder" || exit
  else
    cd "$config_path" || exit
  fi
}
# Move and go to the directory
mvg() {
  if [ -d "$2" ]; then
    mv "$1" "$2" && cd "$2" || exit
  else
    mv "$1" "$2"
  fi
}

cd() {
  if [ -n "$1" ]; then
    builtin cd "$@" && ls || return
  else
    builtin cd ~ && ls || return
  fi
}

xdg_dirs() {
  local xdg=(
    "$XDG_CONFIG_HOME"
    "$XDG_CACHE_HOME"
    "$XDG_RUNTIME_DIR"
    "$XDG_STATE_HOME"
    "$XDG_DATA_HOME"
  )
  for i in "${xdg[@]}"; do
    ## echo "$i"
    if [ ! -d "$i" ]; then
      mkdir -p "$i"
    fi
  done
}
xdg_dirs

# fzf
fzvi() {
  local FZF_DEFAULT_COMMAND="fd --follow -tf"
  local file
  file=$(fzf --preview "bat --style=plain --color=always {}")
  [ -n "${file}" ] && "${EDITOR}" "${file}"
}

fzcd() {
  local FZF_DEFAULT_COMMAND="fd --follow -td --hidden -E .git"
  local dir
  dir=$(fzf --preview="if [ -d {} ]; then ls --color=always -A {}; else bat {}; fi" | xargs -r -I {} echo {})
  [ -d "$dir" ] && cd "$dir" || return 0
}
