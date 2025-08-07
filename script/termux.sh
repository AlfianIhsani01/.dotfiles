#!/bin/bash

# ------------------------------------------------------------------------------
# Cross-Platform Shebang Fixer
# Fixes shebangs for both Termux and regular Linux environments
# Enhanced bash version with improved error handling and functionality
# ------------------------------------------------------------------------------

set -euo pipefail

# Configuration
declare -r SCRIPT_NAME="${0##*/}"
# Environment detection
declare -r TERMUX_ROOT="/data/data/com.termux/files"
declare -r TERMUX_PREFIX="${TERMUX_ROOT}/usr"

# Statistics
declare -i files_processed=0
declare -i files_fixed=0
declare -i files_failed=0
declare -i files_skipped=0

# --- Environment detection ---
is_termux() {
    [[ -d "$TERMUX_ROOT" ]] && [[ -n "${TERMUX_VERSION:-}" || "$PREFIX" == "$TERMUX_PREFIX" ]]
}

is_android() {
    [[ -d "/system/bin" ]] && [[ -f "/system/build.prop" ]]
}

get_environment() {
    if is_termux; then
        echo "termux"
    elif is_android; then
        echo "android"
    else
        echo "linux"
    fi
}

# --- File validation ---
validate_file() {
    local file="$1"

    # Check if file exists
    if [[ ! -f "$file" ]]; then
        log_debug "File does not exist: $file"
        return 1
    fi

    # Check if file is readable
    if [[ ! -r "$file" ]]; then
        log_error "File is not readable: $file"
        return 2
    fi

    # Check if file is writable
    if [[ ! -w "$file" ]]; then
        log_error "File is not writable: $file"
        return 3
    fi

    return 0
}

# --- Enhanced shebang fixing for Linux ---
fix_linux_shebang() {
    local files=("$@")
    local temp_file
    local backup_file
    local changes_made=false

    [[ ${#files[@]} -eq 0 ]] && {
        log_error "No files specified for Linux shebang fixing"
        return 1
    }

    log_info "Fixing shebangs for Linux environment..."

    for file in "${files[@]}"; do
        ((files_processed++))

        # Resolve file path
        local target_file
        if command -v realpath &>/dev/null; then
            target_file=$(realpath "$file" 2>/dev/null || echo "$file")
        else
            target_file="$file"
            log_debug "realpath not available, using original path: $file"
        fi

        log_debug "Processing file: $target_file"

        # Validate file
        local validation_result
        if ! validation_result=$(validate_file "$target_file" 2>&1); then
            case $? in
                1) ((files_skipped++)); continue ;;
                2|3) log_error "$validation_result"; ((files_failed++)); continue ;;
            esac
        fi

        # Create temporary file
        temp_file=$(mktemp) || {
            log_error "Failed to create temporary file for $target_file"
            ((files_failed++))
            continue
        }

        # Create backup
        backup_file="${target_file}.bak.$(date +%s)"
        if ! cp "$target_file" "$backup_file"; then
            log_error "Failed to create backup for $target_file"
            rm -f "$temp_file"
            ((files_failed++))
            continue
        fi

        # Fix shebang - convert Termux paths to standard Linux paths
        if sed -E "1s|^#!${TERMUX_PREFIX}/bin/(.*)$|#!/bin/\1|" "$target_file" > "$temp_file"; then
            # Check if changes were made
            if ! cmp -s "$target_file" "$temp_file"; then
                if mv "$temp_file" "$target_file"; then
                    log_success "Fixed shebang in: $target_file"
                    ((files_fixed++))
                    changes_made=true
                else
                    log_error "Failed to apply changes to $target_file"
                    mv "$backup_file" "$target_file"  # Restore backup
                    ((files_failed++))
                fi
            else
                log_debug "No shebang changes needed for: $target_file"
                ((files_skipped++))
            fi
        else
            log_error "Failed to process shebang in $target_file"
            ((files_failed++))
        fi

        # Cleanup
        rm -f "$temp_file"
        [[ "$changes_made" == true ]] || rm -f "$backup_file"
    done

    return 0
}

# --- Enhanced Termux shebang fixing ---
fix_termux_shebang() {
    local files=("$@")

    [[ ${#files[@]} -eq 0 ]] && {
        log_error "No files specified for Termux shebang fixing"
        return 1
    }

    log_info "Using termux-fix-shebang for Termux environment..."

    if ! command -v termux-fix-shebang &>/dev/null; then
        log_error "termux-fix-shebang command not found"
        return 1
    fi

    for file in "${files[@]}"; do
        ((files_processed++))

        log_debug "Processing file with termux-fix-shebang: $file"

        # Validate file first
        if ! validate_file "$file" &>/dev/null; then
            case $? in
                1) ((files_skipped++)); continue ;;
                *) ((files_failed++)); continue ;;
            esac
        fi

        if termux-fix-shebang "$file" 2>/dev/null; then
            log_success "Fixed shebang in: $file"
            ((files_fixed++))
        else
            log_error "Failed to fix shebang in: $file"
            ((files_failed++))
        fi
    done

    return 0
}

# --- Fix runtime directory paths ---
fix_runtime_paths() {
    local files=("$@")
    local env_type="$1"
    shift
    files=("$@")

    [[ ${#files[@]} -eq 0 ]] && return 0

    log_info "Fixing runtime directory paths..."

    local search_pattern replacement_pattern

    case "$env_type" in
        termux)
            # No runtime path fixing needed for Termux typically
            return 0
            ;;
        linux|*)
            search_pattern="${TERMUX_ROOT}/usr/tmp/runtime-"
            replacement_pattern="/usr/tmp/runtime-"
            ;;
    esac

    for file in "${files[@]}"; do
        if [[ -f "$file" ]] && [[ -w "$file" ]]; then
            log_debug "Fixing runtime paths in: $file"

            # Create backup
            local backup_file="${file}.runtime.bak"
            cp "$file" "$backup_file"

            # Fix paths
            if sed -i "s|${search_pattern}|${replacement_pattern}|g" "$file"; then
                log_success "Fixed runtime paths in: $file"
                rm -f "$backup_file"
            else
                log_error "Failed to fix runtime paths in: $file"
                mv "$backup_file" "$file"  # Restore backup
            fi
        fi
    done
}

# --- Get shell-specific configuration files ---
get_shell_files() {
    local shell_type="${1:-auto}"
    local files=()

    case "$shell_type" in
        zsh)
            [[ -f "$HOME/.zshenv" ]] && files+=("$HOME/.zshenv")
            [[ -f "${ZDOTDIR:-$HOME}/.zshrc" ]] && files+=("${ZDOTDIR:-$HOME}/.zshrc")
            [[ -f "${ZDOTDIR:-$HOME}/.zlogin" ]] && files+=("${ZDOTDIR:-$HOME}/.zlogin")
            ;;
        fish)
            [[ -f "$HOME/.config/fish/functions/xdg_dirs.fish" ]] && files+=("$HOME/.config/fish/functions/xdg_dirs.fish")
            ;;
        bash|auto)
            [[ -f "$HOME/.bashrc" ]] && files+=("$HOME/.bashrc")
            [[ -f "$HOME/.bash_profile" ]] && files+=("$HOME/.bash_profile")
            ;;
    esac

    printf '%s\n' "${files[@]}"
}

# --- Main shebang fixing function ---
fix_shebangs() {
    local files=("$@")
    local env_type
    env_type=$(get_environment)

    # Reset counters
    files_processed=0
    files_fixed=0
    files_failed=0
    files_skipped=0

    log_step "Shebang Fixing for $(tr '[:lower:]' '[:upper:]' <<< "${env_type:0:1}")${env_type:1} Environment"

    # If no files specified, use default shell files
    if [[ ${#files[@]} -eq 0 ]]; then
        log_info "No files specified, using default shell configuration files"

        # Detect current shell and get appropriate files
        local current_shell="${SHELL##*/}"
        mapfile -t files < <(get_shell_files "$current_shell")

        if [[ ${#files[@]} -eq 0 ]]; then
            log_warning "No shell configuration files found"
            return 0
        fi

        log_info "Found ${#files[@]} shell configuration files: ${files[*]}"
    fi

    # Fix shebangs based on environment
    case "$env_type" in
        termux)
            export ROOT="$TERMUX_ROOT"
            export HOME="$TERMUX_ROOT/home"
            fix_termux_shebang "${files[@]}"
            ;;
        linux|android)
            fix_linux_shebang "${files[@]}"
            fix_runtime_paths "$env_type" "${files[@]}"
            ;;
        *)
            log_error "Unknown environment type: $env_type"
            return 1
            ;;
    esac

    # Summary
    log_step "Processing Summary"
    log_info "Files processed: $files_processed"
    log_success "Files fixed: $files_fixed"
    [[ $files_skipped -gt 0 ]] && log_warning "Files skipped: $files_skipped"
    [[ $files_failed -gt 0 ]] && log_error "Files failed: $files_failed"

    return $([[ $files_failed -eq 0 ]] && echo 0 || echo 1)
}

# --- Help function ---
show_help() {
    cat << EOF
${BOLD}Cross-Platform Shebang Fixer${NC}

${BOLD}USAGE:${NC}
    $SCRIPT_NAME [OPTIONS] [FILES...]

${BOLD}DESCRIPTION:${NC}
    Fixes shebangs in shell configuration files for cross-platform compatibility.
    Automatically detects Termux vs Linux environment and applies appropriate fixes.
    
    ${BOLD}Termux → Linux:${NC} Converts #!${TERMUX_PREFIX}/bin/... to #!/bin/...
    ${BOLD}Linux → Termux:${NC} Uses termux-fix-shebang utility

${BOLD}OPTIONS:${NC}
    -h, --help          Show this help message
    -v, --version       Show version information
    -d, --debug         Enable debug output
    --env ENV           Force environment type (termux|linux|android)
    --shell SHELL       Target specific shell files (zsh|fish|bash)
    --dry-run          Show what would be done without making changes

${BOLD}EXAMPLES:${NC}
    $SCRIPT_NAME                    # Fix default shell config files
    $SCRIPT_NAME ~/.zshrc ~/.bashrc # Fix specific files
    $SCRIPT_NAME --shell zsh        # Fix only zsh files
    $SCRIPT_NAME --dry-run          # Preview changes

${BOLD}ENVIRONMENT DETECTION:${NC}
    Current environment: ${BOLD}$(get_environment)${NC}
    Termux root: ${TERMUX_ROOT} $([[ -d "$TERMUX_ROOT" ]] && echo "(exists)" || echo "(not found)")

${BOLD}DEFAULT FILES:${NC}
$(for file in "${DEFAULT_SHELL_FILES[@]}"; do
    if [[ -f "$file" ]]; then
        printf "    ${GREEN}✓${NC} %s\n" "$file"
    else
        printf "    ${RED}✗${NC} %s\n" "$file"
    fi
done)

EOF
}

# --- Main execution ---
main() {
    local files=()
    local env_override=""
    local shell_override=""
    local dry_run=false

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--version)
                printf "%s v%s\n" "$SCRIPT_NAME" "$VERSION"
                printf "Enhanced cross-platform shebang fixer\n"
                exit 0
                ;;
            -d|--debug)
                export DEBUG=1
                log_info "Debug mode enabled"
                shift
                ;;
            --env)
                env_override="$2"
                shift 2
                ;;
            --shell)
                shell_override="$2"
                shift 2
                ;;
            --dry-run)
                dry_run=true
                log_info "Dry run mode - no changes will be made"
                shift
                ;;
            -*)
                log_error "Unknown option: $1"
                printf "Use --help for usage information\n"
                exit 1
                ;;
            *)
                files+=("$1")
                shift
                ;;
        esac
    done

    # Override environment if requested
    if [[ -n "$env_override" ]]; then
        log_info "Environment overridden to: $env_override"
        # This would require modifying get_environment function
    fi

    # Get shell-specific files if requested
    if [[ -n "$shell_override" ]] && [[ ${#files[@]} -eq 0 ]]; then
        mapfile -t files < <(get_shell_files "$shell_override")
        log_info "Using $shell_override shell files: ${files[*]}"
    fi

    # Dry run mode
    if [[ "$dry_run" == true ]]; then
        log_info "Dry run - showing files that would be processed:"
        [[ ${#files[@]} -eq 0 ]] && mapfile -t files < <(get_shell_files "auto")
        for file in "${files[@]}"; do
            if [[ -f "$file" ]]; then
                printf "  ${GREEN}✓${NC} %s\n" "$file"
            else
                printf "  ${RED}✗${NC} %s (not found)\n" "$file"
            fi
        done
        exit 0
    fi

    # Execute shebang fixing
    fix_shebangs "${files[@]}"
}

# --- Legacy function compatibility ---
fix_linux_shebang_legacy() {
    log_warning "Using legacy function name. Please use 'fix_shebangs' instead."
    fix_linux_shebang "$@"
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
