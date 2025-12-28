#!/usr/bin/env bash

# shell=${SHELL##*/*/}
# eval "$(fzf --bash)"
# eval "$(atuin init bash)"
# eval "$(starship init $shell)"
# eval "$(zoxide init $shell | sed 's/builtin cd -- "$@"/builtin cd -- "$@" \&\& ls || return/')"
eval "$(zoxide init posix --hook prompt | sed 's/command cd "$@"/command cd "$@" \&\& ls || return 0/')"
# unset shell
