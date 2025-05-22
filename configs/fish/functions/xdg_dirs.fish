# Save as ~/.config/fish/functions/xdg_dirs.fish
function xdg_dirs
    set -gx XDG_CONFIG_HOME "$HOME/.config"
    set -gx XDG_DATA_HOME "$HOME/.local/share"
    set -gx XDG_STATE_HOME "$HOME/.local/state"
    set -gx XDG_CACHE_HOME "$HOME/.cache"
    set -gx XDG_RUNTIME_DIR "$ROOT/usr/tmp/runtime-$UID"
    
    # Common applications
    set -gx GNUPGHOME "$XDG_DATA_HOME/gnupg"
    set -gx XINITRC "$XDG_CONFIG_HOME/X11/xinitrc"
    set -gx XAUTHORITY "$XDG_RUNTIME_DIR/Xauthority"
    set -gx NPM_CONFIG_USERCONFIG "$XDG_CONFIG_HOME/npm/npmrc"
    set -gx DOCKER_CONFIG "$XDG_CONFIG_HOME/docker"
    set -gx RUSTUP_HOME "$XDG_DATA_HOME/rustup"
    set -gx CARGO_HOME "$XDG_DATA_HOME/cargo"
    # For another app to use xdg base dirs
    set -gx GIT_CONFIG_GLOBAL "$XDG_CONFIG_HOME/git/config"
    set -gx SSH_CONFIG_DIR "$XDG_CONFIG_HOME/ssh"
    set -gx LESSKEY "$XDG_CONFIG_HOME/less/lesskey"
    set -gx LESSHISTFILE "$XDG_CACHE_HOME/less/history"
    set -gx STARSHIP_CONFIG "$XDG_CONFIG_HOME/starship/starship.toml"
    set -gx PATH ~/.local/share/cargo/bin $PATH
        
    # Ensure directories exist
    mkdir -p $XDG_CONFIG_HOME
    mkdir -p $XDG_DATA_HOME
    mkdir -p $XDG_STATE_HOME
    mkdir -p $XDG_CACHE_HOME
end
