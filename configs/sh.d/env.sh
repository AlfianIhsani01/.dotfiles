#!/bin/env bash

## XDG directory
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_RUNTIME_DIR="$HOME/.local/tmp/runtime-$UID"
export XDG_BIN_DIR="$HOME/.local/bin"

export PATH="$PATH:${XDG_BIN_DIR:-$HOME/.local/bin}"
export PATH="$PATH:${XDG_DATA_HOME:-$HOME/.local/share/cargo/bin}"
export PATH="$PATH:${XDG_DATA_HOME:-$HOME/.local/share/nvim/mason/bin}"
export PATH="$PATH:/system/bin"
export PATH="$PATH:${HOME}/.deno/bin"

export DF_HOME="${HOME}/.dotfiles"

## Nodejs
export NPM_CONFIG_USERCONFIG="${XDG_CONFIG_HOME}/npm/npmrc"
export NPM_CONFIG_CACHE="${XDG_CACHE_HOME}/npm"
# export NPM_CONFIG_TMP="${XDG_RUNTIME_DIR}/npm"
export NODE_REPL_HISTORY="${XDG_STATE_HOME}/node_history"

## other
export SSH_CONFIG_DIR="${XDG_CONFIG_HOME}/ssh"
export GIT_CONFIG_GLOBAL="${XDG_CONFIG_HOME:-$HOME/.config}/git/config"
export STARSHIP_CONFIG="${XDG_CONFIG_HOME}/starship/starship.toml"
export CARGO_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/cargo"

export PYTHONHISTORY="${XDG_STATE_HOME:-$HOME/.local/state/python_history}"
# export SHELDON_DATA_DIR="$XDG_DATA_HOME/sheldon"
# export HELIX_RUNTIME="/data/data/com.termux/files/home/.config/helix/runtime"

__xdg_dirs() {
   xdg_dirs=(
      "$XDG_CONFIG_HOME"
      "$XDG_CACHE_HOME"
      "$XDG_RUNTIME_DIR"
      "$XDG_STATE_HOME"
      "$XDG_DATA_HOME"
   )
   for i in "${xdg_dirs[@]}"; do
      if [ ! -d "$i" ]; then
         mkdir -p "$i" || return 1
      fi
   done
   unset -v xdg_dirs
}
__xdg_dirs
unset -f __xdg_dirs
