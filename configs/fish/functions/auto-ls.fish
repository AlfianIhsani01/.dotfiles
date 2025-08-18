#!/usr/bin/env fish
# Prevent loading on dumb terminals
if test "$TERM" = "dumb"
    echo "Dumb/non-tty terminal detected, skipping loading fish-ls"
    return 0
end

function check_prog
    if command -q eza
        set -g ls "eza"
    else if command -q lsd
        set -g ls "lsd"
    else if command -q busybox
        set -g ls "busybox ls"
    else
        set -g ls "ls"  # Fallback to system ls
        return 1
    end
    return 0
end

function set_params
    switch $ls
        case eza
            set -g ls_params \
                --git --icons --group --group-directories-first \
                --time-style=long-iso --color-scale=all

            if test -n "$_LS_PARAMS"
                set ls_params $_LS_PARAMS
            end
        case lsd
            set -g ls_params \
                --icon=always --group-dirs=first --color=always
        case '*'
            set -g ls_params \
                --color=auto
    end
end

function set_alias
    alias ls="$ls $ls_params"
    alias l="$ls --git-ignore $ls_params"
    alias ll="$ls --all --header --long $ls_params"
    alias llm="$ls --all --header --long --sort=modified $ls_params"
    
    # These should also use the detected command
    if test "$ls" = "eza"
        alias la="$ls -lbhHigUmuSa $ls_params"
        alias lx="$ls -lbhHigUmuSa@ $ls_params"
        alias lt="$ls --tree $ls_params"
        alias tree="$ls --tree $ls_params"
    else
        # Fallback for other ls commands
        alias la="$ls -la $ls_params"
        alias lx="$ls -la $ls_params"
        alias lt="find . -type d | head -20"  # Simple tree alternative
        alias tree="find . -type d | head -20"
    end
end

function auto_ls_setup
    switch $AUTOLS
    case 1
        # Function for cd auto list directories
        function auto_ls --on-variable PWD
            command $ls $ls_params
        end
    case '*'
        return 0
    end
end

function auto-ls
    if test (count $argv) -gt 0
        set -g AUTOLS $argv[1]
    end
    
    check_prog
    if test $status -eq 0
        set_params
        set_alias
        auto_ls_setup
    else
        echo "No suitable ls replacement found, using system ls"
        set_params
        set_alias
    end
end

# Initialize if AUTOLS is already set
if test -n "$AUTOLS"
    auto-ls
end
