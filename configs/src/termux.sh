#!/data/data/com.termux/files/usr/bin/env bash
alias pdg='pkg update && pkg upgrade -y'
alias M='termux-media-player'
alias R='termux-reload-settings'


termux-change-font() {
  local linkf="$PWD/$1"
  local linkd="$HOME/.termux"
  if [ -d "$linkd" ] && [ -f "$linkf" ];then
    ln -v -sf "$linkf" "$linkd/font.ttf"
    file "$linkd/font.ttf"
    termux-reload-settings
  else
    echo "$linkf or $linkd does\`t exist"
  fi
}
