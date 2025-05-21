#!/usr/bin/env sh

DOT_URL="https://github.com/AlfianIhsani01/.dotfiles.git"
DOTHOME="$HOME/.dotfiles"
script_name=$(basename "$0")

if [ -d "$HOME/.dotfiles" ] && [ -f "$HOME/.dotfiles/$script_name" ]; then
  export DOTHOME
else
  echo "need to download dotfiles y/n"
  read -r anw
  case "$anw" in
    [Nn]*) exit 1
    ;;
    *)
    check_and_install_packages git
    git clone $DOT_URL $HOME
    export DOTHOME
    ;;
  esac
fi

# Check if script is being executed directly (not sourced)
if [ "$0" = "$script_name" ] || [ "$0" = "./$script_name" ]; then
  # If no arguments are provided, use default list of packages
  if [ $# -eq 0 ]; then
    # Source function definitions and package lists
    . "$DOTHOME/script/functions.sh"
    . "$DOTHOME/script/packages.list"
    # In POSIX sh, we need to pass the packages as individual arguments
    # Assuming packages.list defines a space-separated list of packages
    check_and_install_packages $DEVLANG
    check_and_install_packages $UTILITIES
    check_and_install_packages $DEVTOOLS
  else
    # Use packages provided as arguments
    check_and_install_packages "$@"
  fi
fi

source $DOTHOME/script/
# termux
source ~/.dotfiles/script/termux.sh
