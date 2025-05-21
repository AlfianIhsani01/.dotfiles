if status is-interactive
    # Commands to run in interactive sessions can go here
    starship init fish | source
    zoxide init fish | source
    atuin init fish | source
end

if status --is-login
    clear
    source ~/.config/fastfetch/startup.sh
end

set -x AUTOCD 1
# set -x EZA_PARAMS "--icons=auto"
source ~/.config/fish/functions/fish-eza.fish

sed 's/$(ssh-agent -s)/(ssh-agent -c)/' ~/.config/globrc/alias.sh | source

set -gx EDITOR nvim
# Set XDG Base Directory variables if not already set
set -gx XDG_CONFIG_HOME "$HOME/.config"
set -gx XDG_DATA_HOME "$HOME/.local/share"
set -gx XDG_STATE_HOME "$HOME/.local/state"
set -gx XDG_CACHE_HOME "$HOME/.cache"
set -gx XDG_RUNTIME_DIR "/run/user/$UID"
xdg_dirs

# For another app to use xdg base dirs
set -gx GIT_CONFIG_GLOBAL "$XDG_CONFIG_HOME/git/config"
set -gx SSH_CONFIG_DIR "$XDG_CONFIG_HOME/ssh"
set -gx LESSKEY "$XDG_CONFIG_HOME/less/lesskey"
set -gx LESSHISTFILE "$XDG_CACHE_HOME/less/history"
set -gx STARSHIP_CONFIG "$XDG_CONFIG_HOME/starship/starship.toml"

set -gx PATH ~/.local/share/cargo/bin $PATH
