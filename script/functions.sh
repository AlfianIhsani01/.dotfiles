#!/data/data/com.termux/files/usr/bin/sh

# ------------------------------------------------------------------------------
# setup.sh
# Check if packages are installed and install them if not
# Supports multiple package managers including Termux
# POSIX sh compatible version
# ------------------------------------------------------------------------------

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Tab settings
TAB_SIZE=15

# Detect package manager
detect_package_manager() {
	if command -v pkg >/dev/null 2>&1; then
		echo "termux"
	elif command -v apt-get >/dev/null 2>&1; then
		echo "apt"
	elif command -v dnf >/dev/null 2>&1; then
		echo "dnf"
	elif command -v yum >/dev/null 2>&1; then
		echo "yum"
	elif command -v pacman >/dev/null 2>&1; then
		echo "pacman"
	elif command -v xbps-install >/dev/null 2>&1; then
		echo "xbps"
	elif command -v apk >/dev/null 2>&1; then
		echo "apk"
	elif command -v brew >/dev/null 2>&1; then
		echo "brew"
	else
		echo "unknown"
	fi
}

# Check if a package is installed
is_installed() {
	package=$1
	pkg_manager=$2

	case $pkg_manager in
	apt | termux)
		dpkg -l "$package" >/dev/null 2>&1
		return $?
		;;
	dnf | yum)
		rpm -q "$package" >/dev/null 2>&1
		return $?
		;;
	pacman)
		pacman -Qi "$package" >/dev/null 2>&1
		return $?
		;;
	brew)
		brew list "$package" >/dev/null 2>&1
		return $?
		;;
	xbps)
		xbps-query -l | grep -q " $package-[0-9]" >/dev/null 2>&1
		return $?
		;;
	apk)
		apk info -e "$package" >/dev/null 2>&1
		return $?
		;;
	*)
		return 1
		;;
	esac
}

# Spinner function
spinner() {
	pid=$1
	delay=0.2
	spinstr='-\|/'
	while kill -0 "$pid" 2>/dev/null; do
		temp=${spinstr#?}
		printf " (%c)  " "$spinstr"
		spinstr=$temp${spinstr%"$temp"}
		sleep $delay
		printf "\b\b\b\b\b\b"
	done
}

# Install a package silently with spinner
install_package() {
	package=$1
	pkg_manager=$2

	printf "$BLUE%s$CYAN%s$NC%s" "Installing " "$package" "..."

	cmd=""
	case $pkg_manager in
	apt)
		cmd="sudo apt-get install -y $package"
		;;
	dnf)
		cmd="sudo dnf install -y $package"
		;;
	yum)
		cmd="sudo yum install -y $package"
		;;
	pacman)
		cmd="sudo pacman -S --noconfirm $package"
		;;
	brew)
		cmd="brew install $package"
		;;
	xbps)
		cmd="sudo xbps-install -y $package"
		;;
	termux)
		cmd="pkg install -y $package"
		;;
	apk)
		cmd="sudo apk add $package"
		;;
	*)
		printf "%sUnknown package manager. Cannot install %s.%s\n" "$RED" "$package" "$NC"
		return 1
		;;
	esac

	# Execute installation command with spinner
	eval "$cmd" >/dev/null 2>&1 &
	install_pid=$!
	spinner "$install_pid"

	wait "$install_pid"
	if [ $? -eq 0 ]; then
		printf "$GREEN%s$NC\n" " Done"
		return 0
	else
		printf "$RED%s$NC\n" " Failed"
		return 1
	fi
}

# Check and install packages
check_and_install_packages() {
	pkg_manager=$(detect_package_manager)
	installed_count=0
	missing_count=0

	if [ "$pkg_manager" = "unknown" ]; then
		printf "$RED%s$NC\n" "No supported package manager found."
		exit 1
	fi

	printf "$BLUE%s $CYAN%s $BLUE%s$NC\n" "Using" "$pkg_manager" "package manager"
	printf "\n$YELLOW%s$NC\n" " NO  PACKAGE          STATUS"
	printf "┌──┬────────────────┬───────────────┐\n"

	counter=1
	missing_packages=""

	# Process each package passed as argument
	for package in "$@"; do
		printf "│%2.0d│ %-${TAB_SIZE}s│" "$counter" "$package"
		counter=$((counter + 1))

		if is_installed "$package" "$pkg_manager"; then
			printf "$GREEN%-${TAB_SIZE}s$NC│\n" " installed"
			installed_count=$((installed_count + 1))
		else
			printf "$RED%-${TAB_SIZE}s$NC│\n" " not installed"
			missing_count=$((missing_count + 1))
			missing_packages="$missing_packages $package"
		fi
	done
	printf "└──┴────────────────┴───────────────┘\n"

	if [ -n "$missing_packages" ]; then
		printf "\n$YELLOW%s$NC%s\n" "Some packages are missing:" "$missing_packages"
		printf "Install missing packages? [Yy/Nn]: "
		read -r REPLY
		case "$REPLY" in
		[Nn]*)
			failed_packages="$missing_packages"
			;;
		*)
			failed_packages=""
			for package in $missing_packages; do
				if install_package "$package" "$pkg_manager"; then
					installed_count=$((installed_count + 1))
				else
					failed_packages="$failed_packages $package"
				fi
			done
			;;
		esac
	fi

	# printf "\n$BLUE%s$NC\n" "========= Installation Summary ========="
	printf "$GREEN%s$NC%d/%d\n" "Successfully installed or already present: " "$installed_count" "$((installed_count + missing_count))"
	if [ -n "$failed_packages" ]; then
		printf "$RED%s%s$NC\n" "Failed/skipped packages:" "$failed_packages"
	fi
}
