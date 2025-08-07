#!/bin/bash

# ------------------------------------------------------------------------------
# Stow Deployment Script
# Manages dotfiles deployment using GNU Stow with enhanced error handling
# Enhanced bash version with improved functionality and user experience
# ------------------------------------------------------------------------------

set -euo pipefail

# Configuration
# Stow options
declare -r STOW_VERBOSE_LEVEL=2
declare -a STOW_BASE_OPTIONS=(
    "--verbose=$STOW_VERBOSE_LEVEL"
    "--dotfiles"
    "--no-folding"
)

# Global counters
declare -i deployed_count=0
declare -i failed_count=0
declare -i skipped_count=0

# --- Validate dotfiles directory structure ---
validate_dotfiles_structure() {
    log_debug "Validating dotfiles structure at $DFS_HOME"

    if [[ ! -d "$DFS_HOME" ]]; then
        log_error "Dotfiles directory not found: $DFS_HOME"
        return 1
    fi

    if [[ ! -d "$DFS_HOME/configs" ]]; then
        log_error "Configs directory not found: $DFS_HOME/configs"
        log_info "Expected structure: $DFS_HOME/configs/[package-name]/..."
        return 1
    fi

    # Check if there are any config packages
    local config_count
    config_count=$(find "$DFS_HOME/configs" -maxdepth 1 -type d ! -path "$DFS_HOME/configs" | wc -l)

    if ((config_count == 0)); then
        log_warning "No configuration packages found in $DFS_HOME/configs"
        return 1
    fi

    log_debug "Found $config_count configuration package(s)"
    return 0
}

# --- Create XDG config directory if needed ---
ensure_xdg_config() {
    if [[ ! -d "$XDG_CONFIG_HOME" ]]; then
        log_info "Creating XDG config directory: $XDG_CONFIG_HOME"
        if mkdir -p "$XDG_CONFIG_HOME"; then
            log_success "XDG config directory created"
        else
            log_error "Failed to create XDG config directory"
            return 1
        fi
    else
        log_debug "XDG config directory exists: $XDG_CONFIG_HOME"
    fi
}

# --- Deploy a single configuration package ---
deploy_package() {
    local package_name="$1"
    local package_path="$DFS_HOME"
    local target_path="$XDG_CONFIG_HOME"

    log_info "Deploying package: $package_name"

    # Validate package directory
    if [[ ! -d "$package_path" ]]; then
        log_error "Package directory not found: $package_path"
        ((failed_count++))
        return 1
    fi

    # Check if package has any files
    if [[ -z "$(find "$package_path" -t d 2>/dev/null)" ]]; then
        log_warning "Package $package_name contains no files, skipping"
        ((skipped_count++))
        return 0
    fi

    # Create target directory if it doesn't exist
    if [[ ! -d "$target_path" ]]; then
        log_debug "Creating target directory: $target_path"
        if ! mkdir -p "$target_path"; then
            log_error "Failed to create target directory: $target_path"
            ((failed_count++))
            return 1
        fi
    fi

    # Prepare stow command
    local stow_cmd=(
        stow
        "${STOW_BASE_OPTIONS[@]}"
        "--target=$target_path"
        "--dir=$DFS_HOME"
        "$package_name"
    )

    log_debug "Executing: ${stow_cmd[*]}"

    # Execute stow command with error handling
    local stow_output
    if stow_output=$("${stow_cmd[@]}" 2>&1); then
        log_success "Package $package_name deployed successfully"
        [[ -n "$stow_output" ]] && log_debug "Stow output: $stow_output"
        ((deployed_count++))
        return 0
    else
        log_error "Failed to deploy package $package_name"
        log_error "Stow error: $stow_output"
        ((failed_count++))
        return 1
    fi
}

# --- Undeploy a configuration package ---
undeploy_package() {
    local package_name="$1"
    local target_path="$XDG_CONFIG_HOME/$package_name"

    log_info "Undeploying package: $package_name"

    local stow_cmd=(
        stow
        "${STOW_BASE_OPTIONS[@]}"
        "--delete"
        "--target=$target_path"
        "--dir=$DFS_HOME"
        "$package_name"
    )

    log_debug "Executing: ${stow_cmd[*]}"

    if "${stow_cmd[@]}" &>/dev/null; then
        log_success "Package $package_name undeployed successfully"
        return 0
    else
        log_error "Failed to undeploy package $package_name"
        return 1
    fi
}

# --- Main deployment function ---
deploy() {
    local packages=("$@")
    local operation="${DEPLOY_OPERATION:-deploy}"

    log_step "Starting Dotfiles Deployment"

    # Reset counters
    deployed_count=0
    failed_count=0
    skipped_count=0

    # Check and install stow
    if ! check_and_install_stow; then
        log_error "Cannot proceed without stow"
        return 1
    fi

    # Validate dotfiles structure
    if ! validate_dotfiles_structure; then
        return 1
    fi

    # Ensure XDG config directory exists
    if ! ensure_xdg_config; then
        return 1
    fi

    # Determine packages to deploy
    if [[ ${#packages[@]} -eq 0 ]]; then
        log_info "No specific packages provided, deploying all available packages"
        mapfile -t packages < <(find "$DFS_HOME" -maxdepth 1 -type d ! -path "$DFS_HOME/configs" -exec basename {} \;)
    fi

    if [[ ${#packages[@]} -eq 0 ]]; then
        log_warning "No packages found to deploy"
        return 0
    fi

    log_info "Found ${#packages[@]} package(s) to $operation: ${packages[*]}"

    # Deploy/undeploy each package
    for package in "${packages[@]}"; do
        case "$operation" in
            deploy)
                deploy_package "$package"
                ;;
            undeploy)
                undeploy_package "$package"
                ;;
            *)
                log_error "Unknown operation: $operation"
                return 1
                ;;
        esac
    done

    # Summary
    log_step "Deployment Summary"
    case "$operation" in
        deploy)
            log_success "Deployed: $deployed_count packages"
            ;;
        undeploy)
            log_success "Undeployed: $deployed_count packages"
            ;;
    esac

    [[ $skipped_count -gt 0 ]] && log_warning "Skipped: $skipped_count packages"
    [[ $failed_count -gt 0 ]] && log_error "Failed: $failed_count packages"

    if [[ $failed_count -gt 0 ]]; then
        return 1
    fi

    return 0
}

# --- Undeploy function ---
undeploy() {
    DEPLOY_OPERATION=undeploy deploy "$@"
}

# --- List available packages ---
list_packages() {
    log_step "Available Configuration Packages"

    if ! validate_dotfiles_structure; then
        return 1
    fi

    local packages
    mapfile -t packages < <(find "$DFS_HOME/configs" -maxdepth 1 -type d ! -path "$DFS_HOME/configs" -exec basename {} \; | sort)

    if [[ ${#packages[@]} -eq 0 ]]; then
        log_warning "No configuration packages found"
        return 0
    fi

    printf "${BOLD}Package${NC} %20s ${BOLD}Status${NC}\n" ""
    printf "%-30s %s\n" "$(printf '%.0s─' {1..30})" "$(printf '%.0s─' {1..15})"

    for package in "${packages[@]}"; do
        local status="Not deployed"
        local color="$RED"

        if [[ -L "$XDG_CONFIG_HOME/$package" ]] || [[ -d "$XDG_CONFIG_HOME/$package/.stow-local-ignore" ]]; then
            status="Deployed"
            color="$GREEN"
        fi

        printf "%-30s ${color}%s${NC}\n" "$package" "$status"
    done
}

# --- Help function ---
show_help() {
    cat << EOF
${BOLD}Stow Deployment Script${NC}

${BOLD}USAGE:${NC}
    source ${0##*/}
    deploy [PACKAGES...]         # Deploy specified packages (or all if none specified)
    undeploy [PACKAGES...]       # Undeploy specified packages
    list_packages               # List available packages and their status

${BOLD}DESCRIPTION:${NC}
    Manages dotfiles deployment using GNU Stow with enhanced error handling.
    Automatically installs stow if not available and validates dotfiles structure.

${BOLD}ENVIRONMENT VARIABLES:${NC}
    DFS_HOME           Dotfiles directory (default: \$HOME/.dotfiles)
    XDG_CONFIG_HOME   Config directory (default: \$HOME/.config)
    DEBUG             Enable debug output (set to 1)

${BOLD}EXAMPLES:${NC}
    deploy                      # Deploy all packages
    deploy vim tmux             # Deploy specific packages
    undeploy nvim               # Undeploy neovim config
    list_packages               # Show available packages

EOF
}

# --- Main execution (only if run directly) ---
main() {
    case "${1:-}" in
        -h|--help)
            show_help
            exit 0
            ;;
        deploy)
            shift
            deploy "$@"
            ;;
        undeploy)
            shift
            undeploy "$@"
            ;;
        list|list_packages)
            list_packages
            ;;
        *)
            if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
                log_info "Script executed directly, deploying all packages..."
                deploy "$@"
            else
                log_info "Script sourced, functions available for use"
                log_info "Use 'deploy', 'undeploy', or 'list_packages' functions"
            fi
            ;;
    esac
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
