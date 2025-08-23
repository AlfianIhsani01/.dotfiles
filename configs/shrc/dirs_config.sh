#!/bin/env bash

## XDG directory
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_RUNTIME_DIR="$HOME/.local/tmp/runtime-$UID"

export PATH="$PATH:${XDG_DATA_HOME:-$HOME/.local/share}/cargo/bin"
export DFS_HOME="${HOME}/.dotfiles"

## Nodejs
export NPM_CONFIG_USERCONFIG="${XDG_CONFIG_HOME}/npm/npmrc"
export NPM_CONFIG_CACHE="${XDG_CACHE_HOME}/npm"
# export NPM_CONFIG_TMP="${XDG_RUNTIME_DIR}/npm"
export NODE_REPL_HISTORY="${XDG_DATA_HOME}/node_repl_history"

## other 
export SSH_CONFIG_DIR="${XDG_CONFIG_HOME}/ssh"
export GIT_CONFIG_GLOBAL="${XDG_CONFIG_HOME:-$HOME/.config}/git/config"
export STARSHIP_CONFIG="${XDG_CONFIG_HOME}/starship/starship.toml"
export CARGO_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/cargo"

# export SHELDON_DATA_DIR="$XDG_DATA_HOME/sheldon"
# export HELIX_RUNTIME="/data/data/com.termux/files/home/.config/helix/runtime"
