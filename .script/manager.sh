#!/bin/bash

# ------------------------------------------------------------------------------
# Dotfiles Management Script
# ------------------------------------------------------------------------------

# Configuration
. ./main.sh
. ./installer.sh
# ln options
declare -ra LN_OPTIONS=(
   "--verbose"
   "--relative"
   "--symbolic"
   "--suffix=.bkp"
)

# Global counters
declare -i deployed_count=0
declare -i failed_count=0
declare -i skipped_count=0

# --- Validate dotfiles directory structure ---
validate_dotfiles_dir() {
   _log -t "Validating dotfiles structure at $DF_HOME"

   if validate_dotfiles; then
      _log -e "Dotfiles directory not found or invalid in $DF_HOME"
      return 1
   fi

   # Check if there are any config packages
   local config_count
   config_count=$(find "$DF_HOME" -maxdepth 1 -type d ! -path "$DF_HOME/.*" -and ! -path "$DF_HOME" | wc -l)

   if [ -z "${config_count}" ]; then
      _log -w "No configuration packages found in $DF_HOME/.*"
      return 1
   fi

   _log -i "Found ${config_count} configuration package(s)"
   return 0
}

# --- Create directory if needed ---
ensure_path() {
   local path="$1"
   if [[ ! -d $path ]]; then
      _log -i "Creating directory: $path"
      if mkdir -p "$path"; then
         _log -s "$path directory created"
      else
         _log -e "Failed to create directory"
         return 1
      fi
   else
      return 0
   fi
}

# --- Deploy a single configuration package ---
deploy_package() {
   local package_name="$1"
   local target_path="$2"

   _log -i "Deploying package: $package_name"

   # Validate package directory
   if [[ ! -d "$DF_HOME/$package_name" ]]; then
      _log -e "Package directory not found: $package_name"
      return 1
   fi

   # Check if package has any files
   if [[ -z "$(find "$DF_HOME/$package_name" -type d 2>/dev/null)" ]]; then
      _log -w "Package $package_name contains no files, skipping deployment"
      return 0
   fi

   # Create target directory if it doesn't exist
   if ! ensure_path "$target_path"; then
      return 1
   fi

   # Prepare linking
   local cmd=(
      ln
      "${LN_OPTIONS[@]}"
      "$DF_HOME/$package_name"
      "$target_path"
   )

   _log -f "%s\n%s\n" "Executing:" "${cmd[*]}"

   # Execute command with error handling
   local output
   if output=$("${cmd[@]}" 2>&1); then
      _log -s "Package $package_name deployed successfully"
      [[ -n "$output" ]] && _log -t "Output: $output"
      return 0
   else
      _log -e "Failed to deploy package $package_name"
      _log -e "Error: $output"
      return 1
   fi
}

# --- Undeploy a configuration package ---
add_package() {
   local package_group="$DF_HOME/$1"
   shift
   local package_target=("$@")

   if [[ ${#package_target[@]} -eq 0 ]]; then
      _log -e "Please specified target file/folder"
      return 1
   fi

   if ! ensure_path "$package_group"; then
      return 1
   fi

   _log -t "Add ${package_target[*]} to dotfiles"

   local cmd=(
      mv
      "--verbose"
      "${package_target[@]}"
      "$package_group"
   )

   _log -t "Executing: ${cmd[*]}"

   local output
   if output=$("${cmd[@]}" 2>&1); then
      _log -s "Package ${package_target[*]} added successfully"
      [[ -n "$output" ]] && _log "$output"
      return 0
   else
      _log -e "Failed to add ${package_target[*]} into dotfiles"
      _log -e "Error: $output"
      if [[ -z $(find "$package_group" -type d 2>/dev/null) && -d $package_group ]]; then
         rmdir "$package_group"
      fi
      return 1
   fi
}

# --- Main deployment function ---
deploy() {
   local packages=("$@")

   _log -t "Starting Dotfiles Deployment"

   # Reset counters
   deployed_count=0
   failed_count=0
   skipped_count=0

   # Validate dotfiles structure
   if ! validate_dotfiles_dir; then
      return 1
   fi

   # Determine packages to deploy
   if [[ ${#packages[@]} -eq 0 ]]; then
      _log -i "No specific packages provided, deploying all available packages"
      if prompt_yes_no "Do you want to deploy all packages?"; then
         mapfile -t packages < <(find "$DF_HOME" -maxdepth 1 -type d ! -path "$DF_HOME/.*" -exec basename {} \;)
         if [[ ${#packages[@]} -eq 0 ]]; then
            _log -w "No packages found to deploy"
            return 1
         fi
      else
         _log -i "Canceling package deployment"
         return 1
      fi
   else
      for package in "${packages[@]}"; do
         # Ensure packages exists
         if [[ ! -d "$DF_HOME/$package" ]]; then
            _log -e "$package not found in dotfiles"
            return 1
         fi
      done
   fi

   _log -i "Found ${#packages[@]} package(s) in dotfiles"

   # Deploy each package
   for package in "${packages[@]}"; do
      if [[ -z ${CONF_PACK[$package]} ]]; then
         _log -w "$package don\'t have target path configured"
         ((skipped_count++))
         continue
      fi
      if deploy_package "$package" "${CONF_PACK[$package]}"; then
         ((deployed_count++))
      else
         ((failed_count++))
      fi
   done

   # Summary
   _log step "Deployment Summary"
   _log -i "Deployed: $deployed_count packages"

   [[ $skipped_count -gt 0 ]] && _log -w "Skipped: $skipped_count packages"
   [[ $failed_count -gt 0 ]] && _log -e "Failed: $failed_count packages"

   if [[ $failed_count -gt 0 ]]; then
      return 1
   fi

   return 0
}

# --- List available packages ---
list_packages() {
   _log -t "Available Configuration Packages"

   if ! validate_dotfiles_dir; then
      return 1
   fi

   local packages
   mapfile -t packages < <(find "$DF_HOME" -maxdepth 1 -type d ! -path "$DF_HOME/.*" -and ! -path "$DF_HOME" -exec basename {} \; | sort)

   if [[ ${#packages[@]} -eq 0 ]]; then
      _log -w "No configuration packages found"
      return 0
   fi

   printf "${BOLD}Package${NC} %20s ${BOLD}Status${NC}\n" ""
   printf "%-30s %s\n" "$(printf '%.0s─' {1..30})" "$(printf '%.0s─' {1..15})"

   for package in "${packages[@]}"; do
      local status="Not deployed"
      local color="$RED"

      if [[ -L ${CONF_PACK[$package]} ]]; then
         status="Deployed"
         color="$GREEN"
      fi

      printf "%-30s ${color}%s${NC}\n" "$package" "$status"
   done
}

# --- Help function ---
show_help() {
   cat <<EOF
Dotfiles Deployment Script

USAGE:
    source ${0##*/}
    deploy [PACKAGES...]         # Deploy specified packages (or all if none specified)
    undeploy [PACKAGES...]       # Undeploy specified packages
    list-packages                # List available packages and their status

DESCRIPTION:
    Manages dotfiles deployment using GNU Stow with enhanced error handling.
    Automatically installs stow if not available and validates dotfiles structure.

ENVIRONMENT VARIABLES:
    DF_HOME           Dotfiles directory (default: \$HOME/.dotfiles)
    XDG_CONFIG_HOME   Config directory (default: \$HOME/.config)
    DEBUG             Enable debug output (set to 1)

EXAMPLES:
    deploy                      # Deploy all packages
    deploy vim tmux             # Deploy specific packages
    undeploy nvim               # Undeploy neovim config
    list-packages               # Show available packages

EOF
}

# --- Main execution (only if run directly) ---
main() {
   case "${1:-}" in
   -h | --help)
      show_help
      exit 0
      ;;
   -deploy)
      shift
      deploy "$@"
      ;;
   -undeploy)
      shift
      undeploy "$@"
      ;;
   list | list-packages)
      list_packages
      ;;
   *)
      if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
         _log -i "Script executed directly, deploying all packages..."
         deploy "$@"
      else
         _log -i "Script sourced, functions available for use"
         _log -i "Use 'deploy', 'undeploy', or 'list_packages' functions"
      fi
      ;;
   esac
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
   main "$@"
fi
