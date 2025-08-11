#!/bin/bash

# ------------------------------------------------------------------------------
# Dotfiles Setup Script
# Downloads and configures dotfiles with package installation
# Enhanced bash version with improved error handling and user experience
# ------------------------------------------------------------------------------

set -euo pipefail

# Configuration
declare -r DF_URL="https://github.com/AlfianIhsani01/.dotfiles.git"
declare -r DF_HOME="${HOME}/.dotfiles"
declare -r SCRIPT_NAME="${0##*/}"
declare -r MAX_ATTEMPTS=2

# Shell options with full paths
declare -rA SHELL_OPTIONS=(
  [1]="/bin/bash"
  [2]="/usr/bin/fish"
  [3]="/usr/bin/zsh"
)

declare -rA SHELL_NAMES=(
  [1]="bash"
  [2]="fish"
  [3]="zsh"
)
# source_script() {
#   source "$DF_HOME/script/main.sh"
#   source "$DF_HOME/script/stow.sh"
#   source "$DF_HOME/script/termux.sh"
#
# }
# --- Utility functions ---
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
    *) log_warning "Please answer 'y' or 'n'" ;;
    esac
  done
}

# --- Check if dotfiles exist and are valid ---
validate_dotfiles() {
  [[ -d "$DF_HOME" ]] || return 1
  [[ -f "$DF_HOME/$SCRIPT_NAME" ]] || return 1
  [[ -d "$DF_HOME/.git" ]] || return 1
  return 0
}

# --- Download dotfiles with retry logic ---
download_dotfiles() {
  local attempt=1

  # log_step "Checking Dotfiles"

  while ((attempt <= MAX_ATTEMPTS)); do
    log_info "Checking for dotfiles at $DF_HOME (Attempt $attempt of $MAX_ATTEMPTS)"

    if validate_dotfiles; then
      log_success "Dotfiles found and validated at $DF_HOME"
      export DF_HOME
      return 0
    fi

    log_warning "Dotfiles not found or invalid"

    if ((attempt == MAX_ATTEMPTS)); then
      log_error "Maximum attempts reached"
      return 1
    fi

    if prompt_yes_no "Clone dotfiles with Git?"; then
      log_info "Installing git if needed..."
      if command -v check_and_install_packages &>/dev/null; then
        check_and_install_packages git
      else
        # Fallback package installation
        if command -v apt-get &>/dev/null; then
          sudo apt-get update && sudo apt-get install -y git
        elif command -v pkg &>/dev/null; then
          pkg install -y git
        elif command -v dnf &>/dev/null; then
          sudo dnf install -y git
        else
          log_error "Cannot install git automatically. Please install git manually."
          return 1
        fi
      fi

      log_info "Cloning dotfiles repository..."
      if [[ -d "$DF_HOME" ]]; then
        log_warning "Removing existing incomplete dotfiles directory"
        rm -rf "$DF_HOME"
      fi

      if git clone --depth 1 "$DF_URL" "$DF_HOME"; then
        log_success "Dotfiles cloned successfully"
        export DF_HOME
      else
        log_error "Failed to clone dotfiles repository"
        ((attempt++))
        continue
      fi
    else
      log_error "Cannot proceed without dotfiles"
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
    log_info "Sourcing $script_name..."
    # shellcheck source=/dev/null
    source "$DF_HOME/$script_path"
    return 0
  else
    log_warning "$script_name not found at $DF_HOME/$script_path"
    return 1
  fi
}

# --- Install packages from dotfiles configuration ---
install_packages() {
  log_step "Installing Packages"

  # Source package lists
  if source_dotfiles_script "script/packages.list"; then
    local package_groups=()

    # Check which package groups are defined
    [[ -n "${DEVLANG:-}" ]] && package_groups+=(DEVLANG)
    [[ -n "${UTILITIES:-}" ]] && package_groups+=(UTILITIES)
    [[ -n "${DEVTOOLS:-}" ]] && package_groups+=(DEVTOOLS)

    if [[ ${#package_groups[@]} -gt 0 ]]; then
      for group in "${package_groups[@]}"; do
        local packages
        case "$group" in
        DEVLANG) packages=($DEVLANG) ;;
        UTILITIES) packages=($UTILITIES) ;;
        DEVTOOLS) packages=($DEVTOOLS) ;;
        esac

        log_info "Installing $group packages: ${packages[*]}"
        if command -v check_and_install_packages &>/dev/null; then
          check_and_install_packages "${packages[@]}"
        else
          log_warning "check_and_install_packages function not available"
        fi
      done
    else
      log_warning "No package groups found in packages.list"
    fi
  else
    log_warning "Package list not found, skipping package installation"
  fi
}

# --- Deploy dotfiles using stow ---
deploy_dotfiles() {
  log_step "Deploying Dotfiles"

  if source_dotfiles_script "script/stow.sh"; then
    if command -v deploy &>/dev/null; then
      log_info "Deploying dotfiles with stow..."
      deploy
      log_success "Dotfiles deployed successfully"
    else
      log_warning "Deploy function not found in symlink.sh"
    fi
  else
    log_warning "stow script not found, skipping dotfile deployment"
  fi
}

# --- Configure login shell ---
configure_shell() {
  log_step "Configuring Login Shell"

  # Check available shells
  local available_shells=()
  for key in "${!SHELL_OPTIONS[@]}"; do
    if [[ -x "${SHELL_OPTIONS[$key]}" ]]; then
      available_shells+=("$key")
    fi
  done

  if [[ ${#available_shells[@]} -eq 0 ]]; then
    log_warning "No alternative shells found, keeping current shell"
    return 0
  fi

  printf "\n${BOLD}Available shells:${NC}\n"
  for key in "${available_shells[@]}"; do
    printf "  [%s] %s (%s)\n" "$key" "${SHELL_NAMES[$key]}" "${SHELL_OPTIONS[$key]}"
  done
  printf "  [0] Keep current shell\n"

  local choice
  while true; do
    printf "\nChoose login shell [1]: "
    read -r choice
    choice="${choice:-1}"

    case "$choice" in
    0)
      log_info "Keeping current shell: $SHELL"
      return 0
      ;;
    [1-3])
      if [[ " ${available_shells[*]} " =~ " $choice " ]]; then
        local shell_path="${SHELL_OPTIONS[$choice]}"
        local shell_name="${SHELL_NAMES[$choice]}"

        log_info "Setting $shell_name as login shell..."
        if chsh -s "$shell_path"; then
          log_success "$shell_name set as login shell"
          log_info "Please log out and back in for changes to take effect"
        else
          log_error "Failed to change shell to $shell_name"
        fi
        return 0
      else
        log_warning "Shell not available: ${SHELL_NAMES[$choice]}"
      fi
      ;;
    *)
      log_warning "Invalid choice. Please select a number from the list."
      ;;
    esac
  done
}

# --- Configure Termux-specific settings ---
configure_termux() {
  if [[ -n "${TERMUX_VERSION:-}" ]] || [[ "$PREFIX" == *"com.termux"* ]]; then
    log_step "Configuring Termux"

    if source_dotfiles_script "script/termux.sh"; then
      log_success "Termux configuration completed"
    else
      log_warning "Termux script not found, skipping Termux-specific configuration"
    fi
  fi
}

# --- Main setup function ---
main_setup() {
  local packages=("$@")

  log_step "Starting Dotfiles Setup"

  # Download dotfiles if needed
  if ! download_dotfiles; then
    log_error "Failed to obtain dotfiles"
    exit 1
  fi

  # Install packages
  if [[ ${#packages[@]} -gt 0 ]]; then
    log_info "Installing user-specified packages: ${packages[*]}"
    if command -v check_and_install_packages &>/dev/null; then
      check_and_install_packages "${packages[@]}"
    else
      log_warning "Package installation function not available"
    fi
  else
    install_packages
  fi

  # Deploy dotfiles
  deploy_dotfiles

  # Configure shell
  configure_shell

  # Configure Termux if applicable
  configure_termux

  log_success "Dotfiles setup completed successfully!"
  log_info "You may need to restart your terminal or log out/in for all changes to take effect"
}

# --- Help function ---
show_help() {
  cat <<EOF
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

EOF
}

# --- Main execution ---
main() {
  # source_script 
  # Source function definitions
  if ! source_dotfiles_script "script/main.sh"; then
    log_warning "main script not found, using fallback methods"
  fi

  local skip_packages=false
  local skip_shell=false
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
    --no-shell)
      skip_shell=true
      shift
      ;;
    --force)
      force_download=true
      shift
      ;;
    -*)
      log_error "Unknown option: $1"
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
    log_info "Force download requested, removing existing dotfiles"
    rm -rf "$DF_HOME"
  fi

  # Run setup based on how script was called
  if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_setup "${packages[@]}"
  else
    log_info "Script sourced, functions available for use"
  fi
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
unset SCRIPT_NAME
