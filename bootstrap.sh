#!/usr/bin/env sh

DOT_URL="https://github.com/AlfianIhsani01/.dotfiles.git"
DOTHOME="$HOME/.dotfiles"
script_name=$(basename "$0")

attempt=1
max_attempts=2

while [ $attempt -le $max_attempts ]; do
  if [ -d "$HOME/.dotfiles" ] && [ -f "$HOME/.dotfiles/$script_name" ]; then
    export DOTHOME
    echo "Dotfiles found at $DOTHOME."
    break # Exit the loop if dotfiles are found
  else
    echo "Dotfiles not found at $DOTHOME (Attempt $attempt of $max_attempts)."

    if [ $attempt -eq $max_attempts ]; then
      echo "Maximum attempts reached. Exiting."
      exit 1
    fi

    echo "Need to download dotfiles? (y/n)"
    read -r anw
    case "$anw" in
    [Nn]*)
      echo "Exiting as per user request."
      exit 1
      ;;
    *)
      # Assuming 'check_and_install_packages' is a function defined elsewhere
      # If not, you'll need to define it or replace it with direct package installation commands.
      # For example: sudo apt-get update && sudo apt-get install -y git
      echo "Attempting to download dotfiles..."
      check_and_install_packages git         # Make sure this function is defined or replace it
      git clone "$DOT_URL" "$HOME/.dotfiles" # Corrected clone destination to .dotfiles
      export DOTHOME
      ;;
    esac
  fi
  attempt=$((attempt + 1))
  sleep 2 # Add a small delay between attempts
done

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

source "$DOTHOME/script/symlink.sh"
echo "Choose login shell 1)zsh 2)fish"
read -r LOGINSHELL
case "$LOGINSHELL" in
1)
  echo "set zsh as login shell"
  chsh -s "$(which zsh)"
  ;;
2)
  echo "set fish as login shell"
  chsh -s "$(which fish)"
  ;;
*)
  echo "none choosed will use zsh instead"
  chsh -s "$(which zsh)"
  ;;
esac

# termux
source $DOTHOME/script/termux.sh
