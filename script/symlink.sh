

check_stow() {
  # In pure POSIX sh, variables assigned inside a function are global by default.
  # We avoid 'local' for strict POSIX compliance.
  attempt=0
  max_attempts=3

  # The loop condition
  while ! command -v stow >/dev/null 2>&1; do
    # Use single brackets for conditional expression
    if [ "$attempt" -ge "$max_attempts" ]; then
      echo "Error: stow could not be installed after $max_attempts attempts. Exiting."
      return 1 # Indicate failure
    fi

    echo "stow is not installed. Attempting to install..."
    check_and_install_packages stow

    # Arithmetic expansion is POSIX
    attempt=$((attempt + 1))
    sleep 2 # Add a small delay between attempts
  done

  echo "stow is installed"
  return 0 # Indicate success
}

deploy() {
  STOW_DIR="$DOTHOME"
  if check_stow; then
      for packs in "$STOW_DIR"/configs/*
      do
          pack_name=$(basename "$packs")
          if [ ! -d "$XDG_CONFIG_HOME/$pack_name" ]; then
              mkdir -p "$XDG_CONFIG_HOME/$pack_name"
              stow --dotfiles -t "$XDG_CONFIG_HOME/$pack_name" -d "$STOW_DIR/configs" "$pack_name"
          fi
      done
  fi
}
