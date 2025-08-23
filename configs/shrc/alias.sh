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
[[ $(command eza 2>/dev/null) ]] && alias ls='eza --color=always --icons' # add colors and file type extensions
alias l='ls -ah -F auto'
alias la='ls -Alh'               # show hidden files
alias lx='ls -lXBh'              # sort by extension
alias lk='ls -lSrh'              # sort by size
alias lc='ls -ltcrh'             # sort by change time
alias lu='ls -lturh'             # sort by access time
alias lr='ls -lRh'               # recursive ls
alias lt='ls -ltrh'              # sort by date
alias lm='ls -alh |more'         # pipe through 'more'
alias lw='ls -xAh'               # wide listing format
alias ll='ls -l -s size -F auto' # long listing format
alias labc='ls -lap'             # alphabetical sort
alias lf='ls -lf | rg -v '^d''   # files only
alias ldir='ls -l | rg '^d''     # directories only
alias lla='ls -Al'               # List and Hidden Files
alias las='ls -A'                # Hidden Files
alias lls='ls -l'                # List

# git
alias g='git'

