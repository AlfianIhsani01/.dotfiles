# Save as ~/.config/fish/functions/xdg_dirs.fish
function xdg_dirs
    set -gx XDG_CONFIG_HOME "$HOME/.config"
    set -gx XDG_DATA_HOME "$HOME/.local/share"
    set -gx XDG_STATE_HOME "$HOME/.local/state"
    set -gx XDG_CACHE_HOME "$HOME/.cache"
    set -gx XDG_RUNTIME_DIR "/run/user/$UID"
    
    # Common applications
    set -gx GNUPGHOME "$XDG_DATA_HOME/gnupg"
    set -gx XINITRC "$XDG_CONFIG_HOME/X11/xinitrc"
    set -gx XAUTHORITY "$XDG_RUNTIME_DIR/Xauthority"
    set -gx NPM_CONFIG_USERCONFIG "$XDG_CONFIG_HOME/npm/npmrc"
    set -gx DOCKER_CONFIG "$XDG_CONFIG_HOME/docker"
    set -gx RUSTUP_HOME "$XDG_DATA_HOME/rustup"
    set -gx CARGO_HOME "$XDG_DATA_HOME/cargo"
    
    # Ensure directories exist
    mkdir -p $XDG_CONFIG_HOME
    mkdir -p $XDG_DATA_HOME
    mkdir -p $XDG_STATE_HOME
    mkdir -p $XDG_CACHE_HOME
end
