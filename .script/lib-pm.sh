#!/data/data/com.termux/files/usr/bin/bash

# ------------------------------------------------------------------------------
# setup.sh
# Check if packages are installed and install them if not
# Supports multiple package managers including Termux
# Improved bash version with enhanced features
# ------------------------------------------------------------------------------

# Package manager commands mapping
declare -rgA PKG_INSTALL_CMDS=(
   [apk]="sudo apk add"
   [apt]="sudo apt-get install -y"
   [brew]="brew install"
   [dnf]="sudo dnf install -y"
   [pacman]="sudo pacman -S --noconfirm"
   [termux]="pkg install -y"
   [xbps]="sudo xbps-install -y"
   [yum]="sudo yum install -y"
)

# Package check commands mapping
declare -rgA PKG_CHECK_CMDS=(
   [apk]="apk info -e"
   [apt]="dpkg -l"
   [brew]="brew list"
   [dnf]="rpm -q"
   [pacman]="pacman -Qi"
   [termux]="dpkg -l"
   [xbps]="xbps-query -l | grep -q"
   [yum]="rpm -q"
)

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
   local pkg_manager="$1"
   local package="$2"
   local check_cmd="${PKG_CHECK_CMDS[$pkg_manager]:-}"

   [[ -z "$check_cmd" ]] && return 1

   case "$pkg_manager" in
   xbps)
      $check_cmd " ${package}-[0-9]" &>/dev/null
      ;;
   *)
      $check_cmd "${package}" &>/dev/null
      ;;
   esac
}

# --- Enhanced spinner with better animation ---
spinner() {
   local pid=$1
   local spinstr='◧◩⬒⬔◨◪⬓⬕'
   local i=0

   tput civis
   tput sc

   while kill -0 "$pid" 2>/dev/null; do
      i=$(((i + 1) % ${#spinstr}))
      tput rc
      _log -f "\r %s " "${spinstr:$i:1}"
      sleep 0.1
   done

   # Restore the cursor
   tput rc # Restore to the last saved position
   tput cnorm
   _log -f "%s\n" " " # Clear the last spinner character
}

# --- Install a package with enhanced error handling ---
install_package() {
   local pkg_manager="$1"
   local package="$2"

   # Check if the package manager is supported
   if [[ -z "${PKG_INSTALL_CMDS[$pkg_manager]}" ]]; then
      _log -e "Unknown package manager: %s\n" "$pkg_manager" >&2
      return 1
   fi

   local install_cmd
   install_cmd="${PKG_INSTALL_CMDS[$pkg_manager]}"
   _log -i "Installing %s with %s " "$package" "$pkg_manager"

   # Create temporary _log file and ensure it's deleted on exit
   local temp__log
   temp__log=$(mktemp)
   trap 'rm -f "$temp__log"' RETURN

   # Execute the installation command in the background
   # Note: Using `eval` is generally discouraged but necessary here for command expansion.
   # We carefully construct the command to minimize risk.
   eval "$install_cmd '$package' &>'$temp__log'" &
   local install_pid=$!

   _log -f "\r    %s" "installing $package..."
   spinner "$install_pid" >/dev/tty

   # Wait for the background process to finish and check its exit status
   if wait "$install_pid"; then
      _log -s "Success"
      return 0
   fi
   _log -w "Failed"
   _log "Installation log:" >&2
   tail -n 10 "$temp__log" >&2 # Show the last 10 lines of the _log
   _log "---"
   return 1
}

# --- Display package status table ---
display_package_table() {
   local check_cmd="$1"
   local messages="$2"
   shift && shift
   local packages=("$@")
   local missing_packages=()

   if [[ $messages == *"/"* ]]; then
      local msg_true="${messages/\/*/}"
      local msg_false="${messages/*\//}"
   else
      _log -w "Expecting massages to use slash separated value"
      return 1
   fi

   _log -f "${BLUE}${BOLD}%-18s %s${NC}\n" "Package" "Status"

   for package in "${packages[@]}"; do
      _log -f "%-14s " "$package"

      if $check_cmd "$package"; then
         _log "${GREEN}$msg_true${NC}"
      else
         _log "${RED}$msg_false${NC}"
         missing_packages+=("$package")
      fi
   done
   echo "${missing_packages[@]}"
}

# --- Interactive package installation ---
install_missing_packages() {
   local pkg_manager="$1"
   shift
   local missing_packages=("$@")
   local failed_packages=()
   local choice

   _log -i "Missing packages: ${missing_packages[*]}"

   # Enhanced prompt with better options
   while true; do
      _log -i "Choose an option:"
      _log -f "%s\n" "[a] Install all missing packages"
      _log -f "%s\n" "[s] Select packages to install"
      _log -f "%s\n" "[n] Skip installation"
      _log -f "%s" "Choice [a/s/n]: "
      read -r choice

      case "${choice,,}" in
      a | all)
         _log -i "Installing all missing packages..."
         for package in "${missing_packages[@]}"; do
            install_package "$pkg_manager" "$package" ||
               failed_packages+=("$package")
         done
         break
         ;;
      s | select)
         _log -i "Select packages to install (space-separated numbers):"
         for i in "${!missing_packages[@]}"; do
            _log -f "  [%d] %s\n" "$((i + 1))" "${missing_packages[i]}"
         done
         _log -f "%s" "Enter numbers 1-${#missing_packages[@]}: "
         read -ra selections

         for selection in "${selections[@]}"; do
            local pkg="${missing_packages[$((selection - 1))]}"
            if [[ "$selection" =~ ^[0-9]+$ && $selection -ge 1 && $selection -le ${#missing_packages[@]} ]]; then
               install_package "$pkg_manager" "$pkg" ||
                  failed_packages+=("$pkg")
            else
               _log -e "${selection[*]}: please insert valid numbers"
            fi
         done
         break
         ;;
      n | no | skip)
         _log -w "Skipping package installation"
         failed_packages=("${missing_packages[@]}")
         break
         ;;
      *)
         _log -e "Invalid choice. Please enter 'a', 's', or 'n'."
         ;;
      esac
   done
   echo "${failed_packages[@]}"
}

# --- Main function ---
check_n_install() {
   [[ $# -eq 0 ]] && {
      _log -e "No packages specified"
      printf "Usage: %s [PACKAGE1] [PACKAGE2] [...]\n" "${0##*/}"
      exit 1
   }

   local pkg_manager
   pkg_manager=$(detect_package_manager)

   [[ "$pkg_manager" == "unknown" ]] && {
      _log -e "No supported package manager found"
      _log -i "Supported package managers: apt, dnf, yum, pacman, brew, xbp, apk"
      exit 1
   }

   _log -i "Using $pkg_manager package manager"

   # Display package status and get missing packages
   local missing_packages=()
   read -ra missing_packages <<<"$(display_package_table "is_installed $pkg_manager" "installed/not installed" "$@")"
   echo "${missing_packages[*]}" | termux-toast

   # Install missing packages if any
   local failed_packages=()
   if [[ ${missing_packages[0]} != "" ]]; then
      read -ra failed_packages <<<"$(install_missing_packages "$pkg_manager" "${missing_packages[@]}")"
   fi
   failed_counts=${#failed_packages[*]}

   # Final summary
   _log -t "INSTALLATION SUMMARY"
   _log -s "$(($# - failed_counts))/$# Packages installed or already present"

   if [[ ${failed_packages[*]} != "" || ${failed_packages[*]} -gt 1 ]]; then
      _log -w "Failed/skipped packages: ${failed_packages[*]}"
      exit 1
   fi

   _log -s "All packages are now available!"
}

# --- Script execution ---
# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
   check_n_install "$@"
fi
