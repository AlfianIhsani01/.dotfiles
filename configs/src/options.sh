#!/bin/env bash

# General
# export LC_CTYPE="C.UTF-8"
# export LC_ALL="${LC_ALL:-C.UTF-8}"
# export VISUAL="termux-open"
export EDITOR="nvim"

# History
export HISTFILE=~/.history
export HISTFILESIZE=2000
export HISTSIZE=500
export HISTTIMEFORMAT="%F %T " # add timestamp to history

# Don't put duplicate lines in the history and do not add lines that start with a space
export HISTCONTROL=erasedups:ignoredups:ignorespace

# fzf
export FZF_DEFAULT_COMMAND="fd --hidden
                               --follow
                                -E .git 
                                -E .ssh
                                -E .cache 
                                -E '${XDG_DATA_DIR}'
                                -E '${XDG_CACHE_DIR}'"
export FZF_DEFAULT_OPTS="--height 25%
                         --layout=default
                         --border
                         --ansi
                         --prompt='❯ '
                         --color=hl:#2dd4bf"
