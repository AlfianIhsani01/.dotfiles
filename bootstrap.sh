#!/data/data/com.termux/files/usr/bin/env bash

# ------------------------------------------------------------------------------
# Dotfiles Setup Script
# Downloads and configures dotfiles with package installation
# Enhanced bash version with improved error handling and user experience
# ------------------------------------------------------------------------------

set -euo pipefail

# Packages
declare -rA PACKAGES=(
   [1]="neovim"
   [2]="fzf"
   [3]="tmux"
   [4]="stow"
   [5]="git"
)

# Configuration
declare -r DF_URL="https://github.com/AlfianIhsani01/.dotfiles.git"
declare -r DF_HOME="${HOME}/.dotfiles"
declare -r SCRIPT_NAME="${0##*/}"
declare -r MAX_ATTEMPTS=2

# --- Check if dotfiles exist and are valid ---
validate_dotfiles() {
   [[ -d "$DF_HOME" ]] || return 1
   [[ -f "$DF_HOME/$SCRIPT_NAME" ]] || return 1
   [[ -d "$DF_HOME/.git" ]] || return 1
   return 0
}

# --- Download dotfiles with retry logic ---
check_dotfiles() {
   local attempt=0

   echo "Checking Dotfiles"

   while ((attempt <= MAX_ATTEMPTS)); do
      echo "Checking for dotfiles at $DF_HOME (Attempt $attempt of $MAX_ATTEMPTS)"

      if validate_dotfiles; then
         echo "Dotfiles found and validated at $DF_HOME"
         export DF_HOME
         return 0
      fi

      echo "Dotfiles not found or invalid"

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
               echo "Cannot install git automatically. Please install git manually."
               return 1
            fi
         fi

         echo "Cloning dotfiles repository..."
         if [[ -d "$DF_HOME" ]]; then
            echo "Removing existing incomplete dotfiles directory"
            rm -rf "$DF_HOME"
         fi

         if git clone --depth 1 "$DF_URL" "$DF_HOME"; then
            echo "Dotfiles cloned successfully"
            export DF_HOME
         else
            echo "Failed to clone dotfiles repository"
            ((attempt++))
            continue
         fi
      else
         echo "Cannot proceed without dotfiles"
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
      log -i "Sourcing $script_name..."
      # shellcheck source=/dev/null
      source "$DF_HOME/$script_path"
      return 0
   else
      log -w "$script_name not found at $DF_HOME/$script_path"
      return 1
   fi
}

# --- Install packages from dotfiles configuration ---
install_packages() {
   log -t "Installing Packages"

   # Source package lists
   if [[ ${#PACKAGES[@]} -gt 0 ]]; then
      for pkg in "${PACKAGES[@]}"; do
         local packages

         log -i "Installing $pkg"
         if command -v check_and_install_packages &>/dev/null; then
            check_and_install_packages "${packages[@]}"
         else
            log -w "check_and_install_packages function not available"
         fi
      done
   else
      log -w "Package list not found, skipping package installation"
   fi
}

# --- Deploy dotfiles using stow ---
deploy_dotfiles() {
   log -t "Deploying Dotfiles"

   if source_dotfiles_script "script/stow.sh"; then
      if command -v deploy &>/dev/null; then
         log -i "Deploying dotfiles with stow..."
         deploy
         log -s "Dotfiles deployed successfully"
      else
         log -w "Deploy function not found in symlink.sh"
      fi
   else
      log -w "stow script not found, skipping dotfile deployment"
   fi
}

# --- Configure Termux-specific settings ---
configure_termux() {
   if [[ -n "${TERMUX_VERSION:-}" ]] || [[ "$PREFIX" == *"com.termux"* ]]; then
      log -t "Configuring Termux"

      if source_dotfiles_script "script/termux.sh"; then
         log -s "Termux configuration completed"
      else
         log -w "Termux script not found, skipping Termux-specific configuration"
      fi
   fi
}

# --- Main setup function ---
main_setup() {
   local packages=("$@")

   echo "Starting Dotfiles Setup"

   # Download dotfiles if needed
   if ! check_dotfiles; then
      echo "Failed to obtain dotfiles"
      exit 1
   fi

   # Source function definitions
   if ! source_dotfiles_script "script/main.sh"; then
      log -w "main script not found, using fallback methods"
   fi

   # Install packages
   if [[ ${#packages[@]} -gt 0 ]] && [[ $skip_packages == "false" ]]; then
      log -i "Installing user-specified packages: ${packages[*]}"
      if command -v check_and_install_packages &>/dev/null; then
         check_and_install_packages "${packages[@]}"
      else
         log -w "Package installation function not available"
      fi
   else
      install_packages
   fi

   # Deploy dotfiles
   deploy_dotfiles

   # Configure Termux if applicable
   configure_termux

   log -s "Dotfiles setup completed successfully!"
   log -i "You may need to restart your terminal or log out/in for all changes to take effect"
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
      *) log -w "Please answer 'y' or 'n'" ;;
      esac
   done
}
# --- Help function ---
show_help() {
   echo -e "
${BOLD}Dotfiles Setup Script${NC}

${BOLD}USAGE:${NC}
    $SCRIPT_NAME [OPTIONS] [PACKAGES...]

${BOLD}DESCRIPTION:${NC}
    Downloads and configures dotfiles from GitHub repository.
    Installs specified packages and sets up the development environment.

${BOLD}OPTIONS:${NC}
    -h, --help      Show this help message
    -v, --version   Show version information
    --no-packages   Skip package installation
    --no-shell      Skip shell configuration
    --force         Force re-download of dotfiles

${BOLD}EXAMPLES:${NC}
    $SCRIPT_NAME                    # Setup with default packages
    $SCRIPT_NAME git vim tmux       # Setup with specific packages
    $SCRIPT_NAME --no-packages      # Setup without installing packages

${BOLD}REPOSITORY:${NC}
    $DF_URL
"
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
      -v | --version)
         printf "Dotfiles Setup Script v2.0\n"
         printf "Enhanced bash version\n"
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
         main_setup
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
      main_setup "${packages[@]}"
   else
      echo "Script sourced, functions available for use"
   fi
}
main "$@"
# Execute main function if script is run directly
# if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
# main "$@"
# fi
unset -v SCRIPT_NAME DF_URL DF_HOME MAX_ATTEMPTS
