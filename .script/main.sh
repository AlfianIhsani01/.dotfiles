#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# Dotfiles Management Script
# Downloads and configures dotfiles with package installation
# ------------------------------------------------------------------------------

set -euo pipefail

# Packages
declare -gA PACKAGES=(
   [1]="neovim"
   [2]="fzf"
   [3]="tmux"
   [4]="kakoune"
   [5]="git"
)

# Dotfiles Packages
declare -gA CONF_PACK=(
   # Packages, Target path
   [termux]="$HOME"
   [configs]="$XDG_CONFIG_HOME"
)

# Configuration
declare DF_URL="https://github.com/AlfianIhsani01/.dotfiles.git"
declare DF_HOME="${HOME}/.dotfiles"
declare SCRIPT_NAME="${0##*/}"
declare MAX_ATTEMPTS=2

# Colors for output
declare -r RED="\033[0;31m"
declare -r GREEN="\033[0;32m"
declare -r YELLOW="\033[0;33m"
declare -r BLUE="\033[0;34m"
declare -r CYAN="\033[0;36m"
declare -r BOLD="\033[1m"
# declare -r DIM="\033[2m"
declare -r NC="\033[0m"

# --- _logging functions ---
_log() {
   local ARG="$1"
   [ "${#@}" -gt 2 ] && shift
   local MESSAGE=("$@")

   case "$ARG" in
   -i | info)
      printf "${BLUE}[i]${NC} %s\n" "${MESSAGE[1]}" >/dev/tty
      ;;
   -s | succes)
      printf "${GREEN}[✔]${NC} %s\n" "${MESSAGE[1]}" >/dev/tty
      ;;
   -w | warning)
      printf "${YELLOW}[?]${NC} %s\n" "${MESSAGE[1]}" >/dev/tty
      ;;
   -e | error)
      printf "${RED}[!]${NC} %s\n" "${MESSAGE[1]}" >&2
      ;;
   -t | step)
      printf "${CYAN}[-]${NC} ${BOLD}%s${NC}\n" "${MESSAGE[1]}" >/dev/tty
      ;;
   -f | format)
      printf "${MESSAGE[@]}" >/dev/tty
      ;;
   *)
      printf "%b\n" "${MESSAGE[@]}" >/dev/tty
      return 1
      ;;
   esac
}

# --- Check if dotfiles exist and are valid ---
validate_dotfiles() {
   [[ -d "$DF_HOME" ]] || return 1
   [[ -f "$DF_HOME/$SCRIPT_NAME" ]] || return 1
   [[ -d "$DF_HOME/.git" ]] || return 1
   return 0
}

# --- Download dotfiles with retry _logic ---
check_dotfiles() {
   local attempt=0

   _log -s "Checking Dotfiles"

   while ((attempt <= MAX_ATTEMPTS)); do
      _log "Checking for dotfiles at $DF_HOME (Attempt $attempt of $MAX_ATTEMPTS)"

      if validate_dotfiles; then
         _log -s "Dotfiles found and validated at $DF_HOME"
         export DF_HOME
         return 0
      fi

      _log -w "Dotfiles not found or invalid"

      if ((attempt == MAX_ATTEMPTS)); then
         echo "Maximum attempts reached"
         return 1
      fi

      if prompt_yes_no "Clone dotfiles with Git?"; then

         echo "Installing git if needed..."
         if ! command -v git --version &>/dev/null; then
            # Fallback package installation
            if command -v apt-get &>/dev/null; then
               sudo apt-get update && sudo apt-get install -y git
            elif command -v pkg &>/dev/null; then
               pkg install -y git
            elif command -v dnf &>/dev/null; then
               sudo dnf install -y git
            else
               _log -e "Cannot install git automatically. Please install git manually."
               return 1
            fi
         fi

         _log -i "Cloning dotfiles repository..."
         if [[ -d "$DF_HOME" ]]; then
            _log -i "Removing existing incomplete dotfiles directory"
            rm -rf "$DF_HOME"
         fi

         if git clone --depth 1 "$DF_URL" "$DF_HOME"; then
            _log -s "Dotfiles cloned successfully"
            export DF_HOME
         else
            _log -e "Failed to clone dotfiles repository"
            ((attempt++))
            continue
         fi
      else
         _log -e "Cannot proceed without dotfiles"
         return 1
      fi

      ((attempt++))
      [[ $attempt -le $MAX_ATTEMPTS ]] && sleep 2
   done

   return 1
}

# --- Source dotfiles scripts safely ---
source_dotfiles_script() {
   local script_path="$1"
   local script_name="${script_path##*/}"

   if [[ -f "$DF_HOME/$script_path" ]]; then
      _log -i "Sourcing $script_name..."
      # shellcheck source=/dev/null
      source "$DF_HOME/$script_path"
      return 0
   else
      _log -w "$script_name not found at $DF_HOME/$script_path"
      return 1
   fi
}

# --- Install packages from dotfiles configuration ---
install_packages() {
   _log -t "Installing Packages"

   # Source package lists
   if [[ ${#PACKAGES[@]} -gt 0 ]]; then
      for pkg in "${PACKAGES[@]}"; do
         local packages

         _log -i "Installing $pkg"
         if command -v check_n_install &>/dev/null; then
            check_n_install "${packages[@]}"
         else
            _log -w "check_n_install function not available"
         fi
      done
   else
      _log -w "Package list not found, skipping package installation"
   fi
}

# --- Deploy dotfiles ---
deploy_dotfiles() {
   _log -t "Deploying Dotfiles"

   if source_dotfiles_script "script/manage.sh"; then
      if command -v deploy &>/dev/null; then
         _log -i "Deploying dotfiles..."
         deploy "${CONF_PACK[@]}"
         _log -s "Dotfiles deployed successfully"
      else
         _log -w "Deploy function not found in symlink.sh"
      fi
   else
      _log -w "Manage script not found, skipping dotfile deployment"
   fi
}

# --- Configure Termux-specific settings ---
configure_termux() {
   if [[ -n "${TERMUX_VERSION:-}" ]] || [[ "$PREFIX" == *"com.termux"* ]]; then
      _log -t "Configuring Termux"

      if source_dotfiles_script "script/termux.sh"; then
         _log -s "Termux configuration completed"
      else
         _log -w "Termux script not found, skipping Termux-specific configuration"
      fi
   fi
}

prompt_yes_no() {
   local prompt="$1"
   local default="${2:-y}"
   local response

   while true; do
      printf "%s [%s]: " "$prompt" "$default"
      read -r response
      response="${response:-$default}"

      case "${response,,}" in
      y | yes) return 0 ;;
      n | no) return 1 ;;
      *) echo "Please answer 'y' or 'n'" ;;
      esac
   done
}
# --- Help function ---
show_help() {
   echo -e "
Dotfiles Management Script

USAGE:
    $SCRIPT_NAME [OPTIONS] [PACKAGES...]

DESCRIPTION:
    Downloads and configures dotfiles from GitHub repository.
    Installs specified packages and sets up the development environment.

OPTIONS:
    -h, --help      Show this help message
    -v, --version   Show version information
    --no-packages   Skip package installation
    --force         Force re-download of dotfiles

EXAMPLES:
    $SCRIPT_NAME                    # Setup with default packages
    $SCRIPT_NAME git vim tmux       # Setup with specific packages
    $SCRIPT_NAME --no-packages      # Setup without installing packages

REPOSITORY:
    $DF_URL
"
}

# --- Main setup function ---
main_setup() {
   local skip_packages="$1"
   shift
   local packages=("$@")
   [ ${#packages[@]} -eq 0 ] &&
      [ ${#PACKAGES[@]} -eq 0 ] &&
      packages=("${PACKAGES[@]}")

   _log -t "Starting Dotfiles Setup"

   # Download dotfiles if needed
   if ! check_dotfiles; then
      _log -e "Failed to obtain dotfiles"
      exit 1
   fi
   # Source function definitions
   if ! source_dotfiles_script "script/installer.sh"; then
      _log -e "Main script not found"
   fi

   # Install packages
   if [[ ${#packages[@]} -gt 0 ]] && [[ $skip_packages == false ]]; then
      _log -i "Installing user-specified packages: ${packages[*]}"
      if command -v check_n_install &>/dev/null; then
         check_n_install "${packages[@]}"
      else
         _log -w "Package installation function not available"
      fi
   else
      install_packages
   fi

   # Deploy dotfiles
   deploy_dotfiles

   # Configure Termux if applicable
   configure_termux

   _log -s "Dotfiles setup completed successfully!"
   _log -i "You may need to restart your terminal or _log out/in for all changes to take effect"
}

# --- Main execution ---
main() {

   local skip_packages=false
   local force_download=false
   local packages=()

   # Parse command line arguments
   while [[ $# -gt 0 ]]; do
      case "$1" in
      -h | --help)
         show_help
         exit 0
         ;;
      --no-packages)
         skip_packages=true
         shift
         ;;
      --force)
         force_download=true
         shift
         ;;
      -*)
         echo "Unknown option: $1"
         printf "Use --help for usage information\n"
         exit 1
         ;;
      *)
         packages+=("$1")
         shift
         ;;
      esac
   done

   # Force download if requested
   if [[ "$force_download" == true ]] && [[ -d "$DF_HOME" ]]; then
      echo "Force download requested, removing existing dotfiles"
      rm -rf "$DF_HOME"
   fi

   # Run setup based on how script was called
   if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
      main_setup "$skip_packages" "${packages[@]}"
   else
      echo "Script sourced, functions available for use"
   fi
}
main "$@"
# Execute main function if script is run directly
# if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
# main "$@"
# fi

# unset -v SCRIPT_NAME DF_URL MAX_ATTEMPTS
