#Alias
alias wd='cd $WORK_DIR'
alias pdg='pkg update && pkg upgrade -y'
alias grep='rg'
alias ssha='eval $(ssh-agent -s)'
alias ssh+='ssh-add'
alias find='fd'
alias ..='cd ..'
alias c='clear'
alias cat='bat'

alias cfg='config_shortcut'
alias cstp='starship config'
alias czrc='vi $ZDOTDIR/.zshrc'

alias v='$EDITOR'
alias vi='$EDITOR'

#lsd
# alias ls='eza --icons=always'
# alias l='ls -l'
# alias ll='ls -l'
# alias la='ls -a'
# alias lla='ls -la'
# alias lt='ls --tree'
# alias ltd='ls --tree -D'

#git
alias gcl='git clone --depth 1'
alias gin='git init'
alias ga='git add'
alias gc='git commit -m'
alias gp='git push origin'
alias gs='git status'

# termux
alias M='termux-media-player'
alias R='termux-reload-settings'
