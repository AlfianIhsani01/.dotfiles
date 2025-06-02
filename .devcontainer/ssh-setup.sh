#!/bin/bash

# Configuration with defaults
SSHD_PORT="${SSHD_PORT:-2222}"
USERNAME="${USERNAME:-automatic}"
USER_UID="${USER_UID:-automatic}"
USER_GID="${USER_GID:-automatic}"
START_SSHD="${START_SSHD:-false}"
NEW_PASSWORD="${NEW_PASSWORD:-skip}"

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
        "auto"|"automatic")
            if [ "${_REMOTE_USER:-root}" != "root" ]; then
                USERNAME="$_REMOTE_USER"
                return
            fi
            
            # Try common usernames
            for user in "devcontainer" "vscode" "node" "codespace" $(awk -F: '$3==1000{print $1}' /etc/passwd); do
                if user_exists "$user"; then
                    USERNAME="$user"
                    return
                fi
            done
            USERNAME="vscode"  # Default fallback
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
        local gid_arg=""
        local uid_arg=""
        
        [ "$USER_GID" != "automatic" ] && gid_arg="--gid $USER_GID"
        [ "$USER_UID" != "automatic" ] && uid_arg="--uid $USER_UID"
        
        groupadd $gid_arg "$USERNAME"
        useradd -s /bin/bash $uid_arg --gid "$USERNAME" -m "$USERNAME"
    fi
    
    # Setup sudo for non-root users
    if [ "$USERNAME" != "root" ]; then
        echo "$USERNAME ALL=(root) NOPASSWD:ALL" > "/etc/sudoers.d/$USERNAME"
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
        "skip")
            ;;
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
    mkdir -p /var/run/sshd
    
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
    cat > /usr/local/share/ssh-init.sh << 'EOF'
#!/usr/bin/env bash
set -e

sudoIf() {
    if [ "$(id -u)" -ne 0 ]; then
        sudo "$@"
    else
        "$@"
    fi
}

# Start SSH server - Void Linux uses runit/sv
if command -v sv >/dev/null 2>&1; then
    # Void Linux with runit
    sudoIf sv up sshd 2>&1 | sudoIf tee /tmp/sshd.log > /dev/null
elif [ -f /etc/init.d/ssh ]; then
    # Traditional SysV init (Debian/Ubuntu)
    sudoIf /etc/init.d/ssh start 2>&1 | sudoIf tee /tmp/sshd.log > /dev/null
elif [ -f /etc/init.d/sshd ]; then
    # Traditional SysV init (CentOS/RHEL)
    sudoIf /etc/init.d/sshd start 2>&1 | sudoIf tee /tmp/sshd.log > /dev/null
elif command -v systemctl >/dev/null 2>&1; then
    # systemd
    sudoIf systemctl start sshd 2>&1 | sudoIf tee /tmp/sshd.log > /dev/null
else
    # Fallback: start sshd directly
    sudoIf /usr/sbin/sshd -D &
    echo "Started sshd directly (PID: $!)" | sudoIf tee /tmp/sshd.log > /dev/null
fi

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
    [ "$START_SSHD" = "true" ] && /usr/local/share/ssh-init.sh
    
    # Output results
    log "Done!\n"
    log "- Port: $SSHD_PORT"
    log "- User: $USERNAME"
    [ "$EMIT_PASSWORD" = "true" ] && log "- Password: $NEW_PASSWORD"
    
    log "\nForward port $SSHD_PORT to your local machine and run:\n"
    log "  ssh -p $SSHD_PORT -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o GlobalKnownHostsFile=/dev/null $USERNAME@localhost\n"
}

main "$@"