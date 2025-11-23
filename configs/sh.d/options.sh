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
export FZF_DEFAULT_COMMAND="\
  fd --hidden\
     --follow\
     -E .git\
     -E .ssh\
     -E .cache\
     -E .local/share\
     -E .cache\
"
export FZF_DEFAULT_OPTS="\
  --style=minimal\
  --height 25%\
  --border\
  --ansi\
  --layout=reverse\
  --prompt='❯ '\
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

# bat
export BAT_THEME="falcon"
# export BAT_THEME_DARK="${XDG_DATA_DIR}/share/nvim/lazy/"
export BAT_THEME_LIGHT="ansi"
export BAT_STYLE="rule"
export BAT_PAGER="less"

export _ZO_DOCTOR=0
# export AUTOLS_OPTIONS="-c 'ls' -l 100"
