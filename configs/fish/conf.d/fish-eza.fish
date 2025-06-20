#!/data/data/com.termux/files/usr/bin/env fish
# Fish shell implementation of zsh-eza
# Author: AlfianIhsani01
# Date: 2025-05-12

# Prevent loading on dumb terminals
if test "$TERM" = "dumb"
    echo "Dumb/non-tty terminal detected, skipping loading fish-eza"
    return 0
end


if command -q eza
    set -l enable_autocd 1
    set -g eza_params \
        --git --icons --group --group-directories-first \
        --time-style=long-iso --color-scale=all

    if test -n "$_EZA_PARAMS"
        set eza_params $_EZA_PARAMS
    end

    alias ls="eza $eza_params"
    alias l="eza --git-ignore $eza_params"
    alias ll="eza --all --header --long $eza_params"
    alias llm="eza --all --header --long --sort=modified $eza_params"
    alias la="eza -lbhHigUmuSa"
    alias lx="eza -lbhHigUmuSa@"
    alias lt="eza --tree $eza_params"
    alias tree="eza --tree $eza_params"

    if string match -qr '^[0-9]+$' "$AUTOCD"
        set enable_autocd "$AUTOCD"
    end
    
    if test "$enable_autocd" = "1"
        # Function for cd auto list directories
        function auto_eza --on-variable PWD
            command eza $eza_params
        end
    end
else
    echo "Please install eza before using this plugin." >&2
    return 1
end

return 0
