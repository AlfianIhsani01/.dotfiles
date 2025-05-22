if status is-interactive
    # Commands to run in interactive sessions can go here
    starship init fish | source
    zoxide init fish | source
    atuin init fish | source
    set -x AUTOCD 1
    source ~/.config/fish/functions/fish-eza.fish
end

if status --is-login
    clear
    source ~/.config/fastfetch/startup.sh
end


sed 's/$(ssh-agent -s)/(ssh-agent -c)/' ~/.config/globrc/alias.sh | source

set -gx EDITOR nvim

xdg_dirs

