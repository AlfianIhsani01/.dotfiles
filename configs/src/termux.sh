#!/data/data/com.termux/files/usr/bin/env bash

# [[ ! -d /data/data/com.termux/files ]]
alias pdg='pkg update && pkg upgrade -y'
alias M='termux-media-player'
alias R='termux-reload-settings'
#
#
termux-change-font() {
  local font="${/storage/emulated/0/Fonts/:-PWD}/$1"
  local target_dir="$HOME/.termux"
  if [ -d "$target_dir" ] && [ -f "$font" ];then
    ln -v -sf "$font" "$target_dir/font.ttf"
    # file "$target_dir/font.ttf"
    termux-reload-settings
  else
    echo "$font or $target_dir does\`t exist"
  fi
}
# https://raw.githubusercontent.com/mbadolato/iTerm2-Color-Schemes/refs/heads/master/termux/Everforest%20Light%20-%20Med.propertieshttps://raw.githubusercontent.com/mbadolato/iTerm2-Color-Schemes/refs/heads/master/termux/Everforest%20Light%20-%20Med.properties
termux-change-color() {
  local color_name=("$@")
  local color_name_to_url
  color_name_to_url=$(echo "${color_name[@]}" | sed 's/ /%20/g')
  local iterm2_repo_url="https://raw.githubusercontent.com/mbadolato/iTerm2-Color-Schemes/refs/heads/master/termux/${color_name_to_url}.properties"
  local colors_prop_name
  colors_prop_name=$(echo "${iterm2_repo_url}" | awk -F/ '{print $NF}')
  echo "${colors_prop_name}"
  if [ "${#color_name[@]}" == 0 ]; then
    echo "plase specified color-scheme name"
  else
    # echo "${iterm2_repo_url}"
    curl -fLO "${iterm2_repo_url}" --output-dir ~/.termux

    if [ -f ~/.termux/"${colors_prop_name}" ] && [ "$(cat ~/.termux/"${colors_prop_name}")" != "" ];then

      ln -sf ~/.termux/"${colors_prop_name}" ~/.termux/colors.properties
    else
      echo "failed to download the color-scheme"
    fi
      termux-reload-settings
      fastfetch
  fi
  }
