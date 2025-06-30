#!/usr/bin/env bash
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
  mkdir -p "$@" && cd "$_"
  return 0
}
# Easy go to config
cfg() {
  folder=$1
  config_path=${XDG_CONFIG_HOME:-$HOME/.config}
  if [ -d "$config_path/$folder" ]; then
    cd "$config_path/$folder"
    return 0
  else
    cd "$config_path"
    return 0
  fi
}
# Move and go to the directory
mvg() {
  if [ -d "$2" ]; then
    mv "$1" "$2" && cd "$2"
  else
    mv "$1" "$2"
  fi
}

function xdg_dirs() {
  local xdg=("$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$XDG_RUNTIME_DIR" "$XDG_STATE_HOME" "$XDG_DATA_HOME")
  for i in "${xdg[@]}"; do
    echo "$i"
    if [ ! -d "$i" ]; then
      mkdir -p "$i"
    fi
  done
}
xdg_dirs
