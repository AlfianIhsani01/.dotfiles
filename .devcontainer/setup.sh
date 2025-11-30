#!/bin/bash

# Configuration with defaults
SSHD_PORT="2222"
USERNAME="akal"
USER_UID="automatic"
USER_GID="automatic"
START_SSHD=true
NEW_PASSWORD="skip"

set -e

# Utility functions
log() { echo -e "$@"; }
user_exists() { id -u "$1" >/dev/null 2>&1; }
group_exists() { getent group "$1" >/dev/null 2>&1; }

# Root check
if [ "$(id -u)" -ne 0 ]; then
   log 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile.'
   exit 1
fi

# Determine username
determine_username() {
   case "$USERNAME" in
   "auto" | "automatic")
      for user in "devcontainer" "vscode" "node" "codespace" $(awk -F: '$3==1000{print $1}' /etc/passwd); do
         if user_exists "$user"; then
            USERNAME="$user"
            return
         fi
      done
      USERNAME="codespace" # Default fallback
      ;;
   "none")
      USERNAME="root"
      USER_UID=0
      USER_GID=0
      ;;
   esac
}

# Create or update user
setup_user() {
   local group_name="$USERNAME"

   if user_exists "$USERNAME"; then
      # Update existing user
      if [ "$USER_GID" != "automatic" ] && [ "$USER_GID" != "$(id -g "$USERNAME")" ]; then
         group_name="$(id -gn "$USERNAME")"
         groupmod --gid "$USER_GID" "$group_name"
         usermod --gid "$USER_GID" "$USERNAME"
      fi

      if [ "$USER_UID" != "automatic" ] && [ "$USER_UID" != "$(id -u "$USERNAME")" ]; then
         usermod --uid "$USER_UID" "$USERNAME"
      fi
   else
      # Create new user
      local gid_arg="1000"
      local uid_arg="1000"

      [ "$USER_GID" != "automatic" ] && gid_arg="--gid $USER_GID"
      [ "$USER_UID" != "automatic" ] && uid_arg="--uid $USER_UID"

      groupadd -g "$gid_arg" "$USERNAME"
      useradd -s /bin/bash -u "$uid_arg" --gid "$USERNAME" -m "$USERNAME"
   fi

   # Setup sudo for non-root users
   if [ "$USERNAME" != "root" ]; then
      echo "$USERNAME ALL=(root) NOPASSWD:ALL" >"/etc/sudoers.d/$USERNAME"
      chmod 0440 "/etc/sudoers.d/$USERNAME"
   fi
}

# Setup user home directory
setup_home_directory() {
   if [ "$USERNAME" = "root" ]; then
      user_home="/root"
   else
      user_home="$(getent passwd "$USERNAME" | cut -d: -f6)"
      [ "$user_home" = "/home/$USERNAME" ] && user_home="/home/$USERNAME"

      if [ ! -d "$user_home" ]; then
         mkdir -p "$user_home"
         chown "$USERNAME:$(id -gn "$USERNAME")" "$user_home"
      fi
   fi
}

# Handle password setup
setup_password() {
   case "$NEW_PASSWORD" in
   "random")
      NEW_PASSWORD="$(openssl rand -hex 16)"
      EMIT_PASSWORD="true"
      echo "$USERNAME:$NEW_PASSWORD" | chpasswd
      ;;
   "skip") ;;
   *)
      echo "$USERNAME:$NEW_PASSWORD" | chpasswd
      ;;
   esac
}

# Setup SSH group and user membership
setup_ssh_group() {
   if ! group_exists ssh; then
      log "Adding 'ssh' group..."
      groupadd ssh
   fi

   [ "$USERNAME" != "root" ] && usermod -aG ssh "$USERNAME"
}

# Configure SSH daemon
configure_sshd() {

   # Apply SSH configuration changes
   sed -i \
      -e 's/session\s*required\s*pam_loginuid\.so/session optional pam_loginuid.so/g' \
      /etc/pam.d/sshd

   sed -i \
      -e 's/#*PermitRootLogin prohibit-password/PermitRootLogin yes/g' \
      -e "s/#*\s*Port\s\+.*/Port $SSHD_PORT/g" \
      -e 's/#\?\s*UsePAM\s\+.*/UsePAM yes/g' \
      /etc/ssh/sshd_config
}

# Create SSH initialization script
create_ssh_init_script() {
   cat >/usr/local/share/ssh-init.sh <<'EOF'
#!/usr/bin/env bash
set -e

sudoIf() {
    if [ "$(id -u)" -ne 0 ]; then
        sudo "$@"
    else
        "$@"
    fi
}

# Start SSH server - detect init system
start_ssh_service() {
     if command -v sshd >/dev/null 2>&1 && command -v which >/dev/null 2>&1; then
        sshdCmd=$(which sshd)
        sudoIf $sshdCmd -D -e 2>&1 | sudoIf tee /tmp/sshd.log > /dev/null
     else
        echo "Could't start sshd"
    fi
}

start_ssh_service

set +e
exec "$@"
EOF
   chmod +x /usr/local/share/ssh-init.sh
}

# Main execution
main() {
   determine_username
   setup_user
   setup_home_directory
   setup_password
   setup_ssh_group
   configure_sshd
   create_ssh_init_script

   # Start SSH daemon if requested
   [ "$START_SSHD" = true ] && /usr/local/share/ssh-init.sh

   # Output results
   log "Done!\n"
   log "- Port: $SSHD_PORT"
   log "- User: $USERNAME"
   [ "$EMIT_PASSWORD" = "true" ] && log "- Password: $NEW_PASSWORD"

   log "\nForward port $SSHD_PORT to your local machine and run:\n"
   log "  ssh -p $SSHD_PORT -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o GlobalKnownHostsFile=/dev/null $USERNAME@localhost\n"
}

main "$@"
