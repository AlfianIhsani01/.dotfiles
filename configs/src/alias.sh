#Alias
alias grep='rg'
alias ssha='eval $(ssh-agent -s) && ssh-add'
# alias ssh+='ssh-add
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias c='clear'
alias cat='bat'
alias find='fd'

alias v='$EDITOR'
alias vi='$EDITOR'

# Alias's for multiple directory listing commands
alias ls='eza --color=always --icons' # add colors and file type extensions
alias l='eza -ah -F auto'
alias la='eza -Alh'               # show hidden files
alias lx='eza -lXBh'              # sort by extension
alias lk='eza -lSrh'              # sort by size
alias lc='eza -ltcrh'             # sort by change time
alias lu='eza -lturh'             # sort by access time
alias lr='eza -lRh'               # recursive ls
alias lt='eza -ltrh'              # sort by date
alias lm='eza -alh |more'         # pipe through 'more'
alias lw='eza -xAh'               # wide listing format
alias ll='eza -l -s size -F auto' # long listing format
alias labc='eza -lap'             # alphabetical sort
alias lf='eza -lf | rg -v '^d''   # files only
alias ldir='eza -l | rg '^d''     # directories only
alias lla='eza -Al'               # List and Hidden Files
alias las='eza -A'                # Hidden Files
alias lls='eza -l'                # List

# git
alias g='git'

# fzf
alias fz-view='selected=$(fzf --preview "bat --number --color=always {}") && [ -n "$selected" ] && nvim "$selected"'
alias fz-cd='cd "$(fzf --preview="if [ -d {} ]; then ls -a {}; else bat {}; fi" | xargs -r -I {} echo {})"'
