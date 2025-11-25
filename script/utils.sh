#!/bin/sh
# GitHub Release Downloader with automatic OS & Architecture matching
# POSIX-compliant version
# Usage: ./download_release.sh <owner/repo> [version]
# Example: ./download_release.sh cli/cli latest

set -e

# Colors for output (optional, will work without)
if [ -t 1 ]; then
   RED='\033[0;31m'
   GREEN='\033[0;32m'
   YELLOW='\033[1;33m'
   BLUE='\033[0;34m'
   NC='\033[0m'
else
   RED=''
   GREEN=''
   YELLOW=''
   BLUE=''
   NC=''
fi

# Detect OS and architecture
detect_system() {
   OS=$(uname -s | tr '[:upper:]' '[:lower:]')
   ARCH=$(uname -m | tr '[:upper:]' '[:lower:]')

   # Normalize OS
   case "$OS" in
   darwin*) OS="darwin" ;;
   linux*) OS="linux" ;;
   mingw* | msys* | cygwin*) OS="windows" ;;
   esac

   # Normalize architecture
   case "$ARCH" in
   x86_64 | amd64) ARCH="x86_64" ;;
   aarch64 | arm64) ARCH="aarch64" ;;
   armv7*) ARCH="armv7" ;;
   i686 | i386 | x86) ARCH="i686" ;;
   esac

   printf "${BLUE}Detected system: %s %s${NC}\n" "$OS" "$ARCH"
}

# Score an asset based on system match
score_asset() {
   asset_name="$1"
   name_lower=$(printf "%s" "$asset_name" | tr '[:upper:]' '[:lower:]')
   score=0

   # Check OS match
   case "$name_lower" in
   *darwin* | *macos* | *osx* | *mac*)
      [ "$OS" = "darwin" ] && score=$((score + 100))
      ;;
   *linux*)
      [ "$OS" = "linux" ] && score=$((score + 100))
      ;;
   *windows* | *win*)
      [ "$OS" = "windows" ] && score=$((score + 100))
      ;;
   esac

   # Check architecture match
   case "$name_lower" in
   *x86_64* | *amd64* | *x64*)
      [ "$ARCH" = "x86_64" ] && score=$((score + 50))
      ;;
   *aarch64* | *arm64*)
      [ "$ARCH" = "aarch64" ] && score=$((score + 50))
      ;;
   *armv7* | *arm*)
      [ "$ARCH" = "armv7" ] && score=$((score + 50))
      ;;
   *i686* | *x86* | *i386*)
      [ "$ARCH" = "i686" ] && score=$((score + 50))
      ;;
   esac

   # Bonus for archive formats
   case "$name_lower" in
   *.tar.gz | *.tgz | *.zip) score=$((score + 10)) ;;
   esac

   # Penalty for checksums and signatures
   case "$name_lower" in
   *.sha* | *.sig | *.asc | *.md5) score=$((score - 1000)) ;;
   esac

   # Penalty for source code
   case "$name_lower" in
   *source*) score=$((score - 500)) ;;
   esac

   printf "%d" "$score"
}

# Fetch release info from GitHub API
fetch_release() {
   owner="$1"
   repo="$2"
   version="$3"

   if [ "$version" = "latest" ]; then
      url="https://api.github.com/repos/$owner/$repo/releases/latest"
   else
      url="https://api.github.com/repos/$owner/$repo/releases/tags/$version"
   fi

   printf "${BLUE}Fetching release info from %s/%s...${NC}\n" "$owner" "$repo"

   # Try curl first, fall back to wget
   if command -v curl >/dev/null 2>&1; then
      response=$(curl -sL -H "Accept: application/vnd.github.v3+json" "$url")
   elif command -v wget >/dev/null 2>&1; then
      response=$(wget -qO- --header="Accept: application/vnd.github.v3+json" "$url")
   else
      printf "${RED}Error: Neither curl nor wget found${NC}\n"
      exit 1
   fi

   if [ -z "$response" ]; then
      printf "${RED}Error: Failed to fetch release information${NC}\n"
      exit 1
   fi

   printf "%s" "$response"
}

# Parse JSON (POSIX-compliant way)
parse_json() {
   json="$1"
   key="$2"

   # Simple JSON parsing - looks for "key": "value"
   printf "%s" "$json" | sed -n 's/.*"'"$key"'": *"\([^"]*\)".*/\1/p' | head -1
}

# Extract assets from JSON
extract_assets() {
   json="$1"

   # Extract the assets array and split into individual asset objects
   printf "%s" "$json" | sed -n '/"assets": \[/,/\]/p' |
      awk '/\{/,/\}/' |
      awk -v RS='},\n' '{print $0 "}"}'
}

# Download file with progress
download_file() {
   url="$1"
   filename="$2"

   printf "${BLUE}Downloading %s...${NC}\n" "$filename"

   if command -v curl >/dev/null 2>&1; then
      curl -L --progress-bar -o "$filename" "$url"
   elif command -v wget >/dev/null 2>&1; then
      wget --show-progress -O "$filename" "$url"
   fi

   printf "${GREEN}✓ Downloaded to %s${NC}\n" "$filename"
}

# Main script
main() {
   if [ $# -lt 1 ]; then
      printf "Usage: %s <owner/repo> [version]\n" "$0"
      printf "Example: %s cli/cli latest\n" "$0"
      exit 1
   fi

   repo_path="$1"
   version="${2:-latest}"

   # Parse owner/repo
   owner=$(printf "%s" "$repo_path" | cut -d'/' -f1)
   repo=$(printf "%s" "$repo_path" | cut -d'/' -f2)

   if [ -z "$owner" ] || [ -z "$repo" ]; then
      printf "${RED}Error: Repository must be in format 'owner/repo'${NC}\n"
      exit 1
   fi

   # Detect system
   detect_system

   # Fetch release data
   release_data=$(fetch_release "$owner" "$repo" "$version")

   # Parse release info
   tag_name=$(parse_json "$release_data" "tag_name")
   published_at=$(parse_json "$release_data" "published_at")

   printf "${GREEN}Release: %s${NC}\n" "$tag_name"
   printf "Published: %s\n\n" "$published_at"

   printf "${YELLOW}Scoring assets:${NC}\n"

   # Create temp file for scoring
   tmpfile=$(mktemp)
   trap 'rm -f "$tmpfile"' EXIT

   # Extract and score assets
   printf "%s" "$release_data" | grep -o '"name": *"[^"]*"' | sed 's/"name": *"\([^"]*\)"/\1/' | while IFS= read -r asset_name; do
      if [ -n "$asset_name" ]; then
         score=$(score_asset "$asset_name")
         printf "%d\t%s\n" "$score" "$asset_name"
      fi
   done | tee "$tmpfile" | awk '{printf "  [%4d] %s\n", $1, $2}'

   # Find best match
   best_line=$(sort -rn "$tmpfile" | head -1)
   best_score=$(printf "%s" "$best_line" | cut -f1)
   best_asset=$(printf "%s" "$best_line" | cut -f2)

   if [ -z "$best_asset" ] || [ "$best_score" -lt 0 ]; then
      printf "\n${RED}✗ No suitable asset found for your system${NC}\n"
      exit 1
   fi

   printf "\n${GREEN}→ Best match: %s${NC}\n" "$best_asset"

   # Get download URL for the best asset
   download_url=$(printf "%s" "$release_data" |
      awk -v name="$best_asset" '
            /"name":/ { if ($0 ~ name) found=1 }
            /"browser_download_url":/ && found {
                match($0, /"browser_download_url": *"([^"]*)"/, arr)
                print arr[1]
                exit
            }
        ')

   if [ -z "$download_url" ]; then
      printf "${RED}Error: Could not find download URL${NC}\n"
      exit 1
   fi

   # Download the file
   download_file "$download_url" "$best_asset"
}

main "$@"
