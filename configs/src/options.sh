#!/data/data/com.termux/files/usr/bin/env bash

# General
export LC_CTYPE="C.UTF-8"
export LC_ALL="${LC_ALL:-C.UTF-8}"
export VISUAL="termux-open"
export EDITOR="nvim"
# History
export HISTFILESIZE=2000
export HISTSIZE=500
export HISTTIMEFORMAT="%F %T " # add timestamp to history

# Don't put duplicate lines in the history and do not add lines that start with a space
export HISTCONTROL=erasedups:ignoredups:ignorespace

