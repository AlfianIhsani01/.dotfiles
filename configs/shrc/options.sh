#!/bin/env bash

# General
# export LC_CTYPE="C.UTF-8"
# export LC_ALL="${LC_ALL:-C.UTF-8}"
export VISUAL="termux-open"
export PAGER='bat'
export EDITOR="nvim"

# History
export HISTFILE=~/.history
export HISTFILESIZE=2000
export HISTSIZE=500
export HISTTIMEFORMAT="%F %T " # add timestamp to history

# Don't put duplicate lines in the history and do not add lines that start with a space
export HISTCONTROL=erasedups:ignoredups:ignorespace

# fzf
export FZF_DEFAULT_COMMAND="
  fd --hidden
     --follow
     -E .git 
     -E .ssh
     -E .cache 
     -E ${XDG_DATA_DIR}
     -E ${XDG_CACHE_DIR}"
export FZF_DEFAULT_OPTS="
  --style=minimal
  --height 25%
  --border
  --ansi
  --layout=reverse
  --prompt='❯ '
  --color='dark\
    ,fg:#b4b4b9\
    ,bg:#020221\
    ,hl:#ffc552\
    ,fg+:#f8f8ff\
    ,bg+:#36363a\
    ,hl+:#ffc552\
    ,query:#f8f8ff\
    ,gutter:#020221\
    ,prompt:#ff5fff\
    ,header:#ffd392\
    ,info:#bfdaff\
    ,pointer:#ffe8c8\
    ,marker:#ff3600\
    ,spinner:#bfdaff\
    ,border:#36363a'\
"

export BAT_THEME="default"
export BAT_THEME_DARK="base16"
export BAT_THEME_LIGHT="ansi"
export BAT_STYLE="rule"
export BAT_PAGER="less"

# export EZA_COLORS="uu=38;5;249:un=38;5;241:gu=38;5;245:gn=38;5;241:da=38;5;245:sn=38;5;7:sb=38;5;7:ur=38;5;3;1:uw=38;5;5;1:ux=38;5;1;1:ue=38;5;1;1:gr=38;5;249:gw=38;5;249:gx=38;5;249:tr=38;5;249:tw=38;5;249:tx=38;5;249:fi=38;5;248:di=38;5;253:ex=38;5;1:xa=38;5;12:*.png=38;5;4:*.jpg=38;5;4:*.gif=38;5;4"
export AUTOLS_OPTIONS="-c 'ls' -l 100"
