#!/bin/bash

# ------------------------------------------------------------------------------
# setup.sh
# Check if packages are installed and install them if not
# Supports multiple package managers including Termux
# Improved bash version with enhanced features
# ------------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, and pipe failures

# Colors for output
declare -r RED='\033[0;31m'
declare -r GREEN='\033[0;32m'
declare -r YELLOW='\033[0;33m'
declare -r BLUE='\033[0;34m'
declare -r CYAN='\033[0;36m'
declare -r BOLD='\033[1m'
declare -r NC='\033[0m'

# Configuration
declare -r TAB_SIZE=15
declare -r SPINNER_DELAY=0.15

# Package manager commands mapping
declare -rA PKG_INSTALL_CMDS=(
    [apt]="sudo apt-get install -y"
    [dnf]="sudo dnf install -y"
    [yum]="sudo yum install -y"
    [pacman]="sudo pacman -S --noconfirm"
    [brew]="brew install"
    [xbps]="sudo xbps-install -y"
    [termux]="pkg install -y"
    [apk]="sudo apk add"
)

# Package check commands mapping
declare -rA PKG_CHECK_CMDS=(
    [apt]="dpkg -l"
    [termux]="dpkg -l"
    [dnf]="rpm -q"
    [yum]="rpm -q"
    [pacman]="pacman -Qi"
    [brew]="brew list"
    [xbps]="xbps-query -l | grep -q"
    [apk]="apk info -e"
)

# Global counters
declare -i installed_count=0
declare -i missing_count=0

# --- Logging functions ---
log_info() {
    printf "${BLUE}[INFO]${NC} %s\n" "$*"
}

log_success() {
    printf "${GREEN}[SUCCESS]${NC} %s\n" "$*"
}

log_warning() {
    printf "${YELLOW}[WARNING]${NC} %s\n" "$*"
}

log_error() {
    printf "${RED}[ERROR]${NC} %s\n" "$*" >&2
}

# --- Package Manager Detection ---
detect_package_manager() {
    local managers=(pkg apt-get dnf yum pacman xbps-install apk brew)
    local manager_names=(termux apt dnf yum pacman xbps apk brew)

    for i in "${!managers[@]}"; do
        if command -v "${managers[i]}" &>/dev/null; then
            echo "${manager_names[i]}"
            return 0
        fi
    done

    echo "unknown"
    return 1
}

# --- Check if a package is installed ---
is_installed() {
    local package="$1"
    local pkg_manager="$2"
    local check_cmd="${PKG_CHECK_CMDS[$pkg_manager]:-}"

    [[ -z "$check_cmd" ]] && return 1

    case "$pkg_manager" in
        xbps)
            $check_cmd " $package-[0-9]" &>/dev/null
            ;;
        *)
            $check_cmd "$package" &>/dev/null
            ;;
    esac
}

# --- Enhanced spinner with better animation ---
spinner() {
    local pid=$1
    local message="${2:-}"
    local delay=$SPINNER_DELAY
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local temp

    [[ -n "$message" ]] && printf "%s " "$message"

    while kill -0 "$pid" 2>/dev/null; do
        temp=${spinstr#?}
        printf " %c  " "${spinstr:0:1}"
        spinstr=$temp${spinstr%"$temp"}
        sleep "$delay"
        printf "\b\b\b\b"
    done
    printf "    \b\b\b\b"  # Clear spinner
}

# --- Install a package with enhanced error handling ---
install_package() {
    local package="$1"
    local pkg_manager="$2"
    local install_cmd="${PKG_INSTALL_CMDS[$pkg_manager]:-}"
    local temp_log

    [[ -z "$install_cmd" ]] && {
        log_error "Unknown package manager: $pkg_manager"
        return 1
    }

    printf "${BLUE}Installing ${CYAN}%s${NC}..." "$package"

    # Create temporary log file
    temp_log=$(mktemp)
    trap "rm -f '$temp_log'" RETURN

    # Execute installation command with spinner
    {
        $install_cmd "$package" &>"$temp_log"
    } &
    local install_pid=$!

    spinner "$install_pid"

    if wait "$install_pid"; then
        printf "${GREEN} ✓ Done${NC}\n"
        ((installed_count++))
        return 0
    else
        printf "${RED} ✗ Failed${NC}\n"
        log_error "Installation failed for $package. Log:"
        tail -5 "$temp_log" | sed 's/^/  /'
        return 1
    fi
}

# --- Display package status table ---
display_package_table() {
    local packages=("$@")
    local pkg_manager="$1"
    shift

    printf "\n${YELLOW}${BOLD} NO  PACKAGE          STATUS${NC}\n"
    printf "┌────┬────────────────┬───────────────┐\n"

    local counter=1
    local missing_packages=()

    for package in "${packages[@]}"; do
        printf "│%3d │ %-14s │" "$counter" "$package"

        if is_installed "$package" "$pkg_manager"; then
            printf "${GREEN}%-${TAB_SIZE}s${NC}│\n" " ✓ installed"
            ((installed_count++))
        else
            printf "${RED}%-${TAB_SIZE}s${NC}│\n" " ✗ not installed"
            ((missing_count++))
            missing_packages+=("$package")
        fi
        ((counter++))
    done

    printf "└────┴────────────────┴───────────────┘\n"
    echo "${missing_packages[@]}"  # Return missing packages
}

# --- Interactive package installation ---
install_missing_packages() {
    local missing_packages=("$@")
    local pkg_manager="$1"
    shift
    local failed_packages=()
    local choice

    [[ ${#missing_packages[@]} -eq 0 ]] && return 0

    printf "\n${YELLOW}Missing packages: ${NC}%s\n" "${missing_packages[*]}"

    # Enhanced prompt with better options
    while true; do
        printf "${BOLD}Choose an option:${NC}\n"
        printf "  ${GREEN}[a]${NC} Install all missing packages\n"
        printf "  ${YELLOW}[s]${NC} Select packages to install\n"
        printf "  ${RED}[n]${NC} Skip installation\n"
        printf "Choice [a/s/n]: "
        read -r choice

        case "${choice,,}" in
            a|all)
                log_info "Installing all missing packages..."
                for package in "${missing_packages[@]}"; do
                    install_package "$package" "$pkg_manager" || failed_packages+=("$package")
                done
                break
                ;;
            s|select)
                log_info "Select packages to install (space-separated numbers):"
                for i in "${!missing_packages[@]}"; do
                    printf "  [%d] %s\n" "$((i+1))" "${missing_packages[i]}"
                done
                printf "Enter numbers: "
                read -ra selections

                for selection in "${selections[@]}"; do
                    if [[ "$selection" =~ ^[0-9]+$ ]] && ((selection >= 1 && selection <= ${#missing_packages[@]})); then
                        local pkg="${missing_packages[$((selection-1))]}"
                        install_package "$pkg" "$pkg_manager" || failed_packages+=("$pkg")
                    fi
                done
                break
                ;;
            n|no|skip)
                log_warning "Skipping package installation"
                failed_packages=("${missing_packages[@]}")
                break
                ;;
            *)
                log_error "Invalid choice. Please enter 'a', 's', or 'n'."
                ;;
        esac
    done

    echo "${failed_packages[@]}"  # Return failed packages
}

# --- Main function ---
check_and_install_packages() {
    [[ $# -eq 0 ]] && {
        log_error "No packages specified"
        printf "Usage: %s <package1> [package2] [...]\n" "${0##*/}"
        exit 1
    }

    local pkg_manager
    pkg_manager=$(detect_package_manager)

    [[ "$pkg_manager" == "unknown" ]] && {
        log_error "No supported package manager found"
        log_info "Supported package managers: apt, dnf, yum, pacman, brew, xbps, apk, termux"
        exit 1
    }

    log_info "Using ${CYAN}$pkg_manager${NC} package manager"

    # Display package status and get missing packages
    local missing_packages
    missing_packages=$(display_package_table "$pkg_manager" "$@")
    read -ra missing_array <<< "$missing_packages"

    # Install missing packages if any
    local failed_packages
    failed_packages=$(install_missing_packages "$pkg_manager" "${missing_array[@]}")
    read -ra failed_array <<< "$failed_packages"

    # Final summary
    printf "\n${BOLD}=== INSTALLATION SUMMARY ===${NC}\n"
    log_success "Successfully installed or already present: $installed_count/$#"

    if [[ ${#failed_array[@]} -gt 0 && -n "${failed_array[0]}" ]]; then
        log_warning "Failed/skipped packages: ${failed_array[*]}"
        exit 1
    fi

    log_success "All packages are now available!"
}

# --- Script execution ---
main() {
    # Handle script arguments
    case "${1:-}" in
        -h|--help)
            printf "Package Installation Script\n\n"
            printf "Usage: %s [OPTIONS] <package1> [package2] [...]\n\n" "${0##*/}"
            printf "Options:\n"
            printf "  -h, --help    Show this help message\n"
            printf "  -v, --version Show version information\n\n"
            printf "Examples:\n"
            printf "  %s git curl wget\n" "${0##*/}"
            printf "  %s python3 nodejs npm\n" "${0##*/}"
            exit 0
            ;;
        -v|--version)
            printf "Package Setup Script v2.0\n"
            printf "Enhanced bash version with improved features\n"
            exit 0
            ;;
        -*)
            log_error "Unknown option: $1"
            printf "Use -h or --help for usage information\n"
            exit 1
            ;;
    esac

    check_and_install_packages "$@"
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
