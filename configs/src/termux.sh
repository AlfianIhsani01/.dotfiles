#!/data/data/com.termux/files/usr/bin/env bash

# [[ ! -d /data/data/com.termux/files ]]
alias pdg='pkg update && pkg upgrade -y'
alias M='termux-media-player'
alias R='termux-reload-settings'
#
#
# termux-change-font() {
#   local font="${/storage/emulated/0/Fonts/:-PWD}/$1"
#   local target_dir="$HOME/.termux"
#   if [ -d "$target_dir" ] && [ -f "$font" ];then
#     ln -v -sf "$font" "$target_dir/font.ttf"
#     # file "$target_dir/font.ttf"
#     termux-reload-settings
#   else
#     echo "$font or $target_dir does\`t exist"
#   fi
# }
