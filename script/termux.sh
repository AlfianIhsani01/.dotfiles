#!/data/data/com.termux/files/usr/bin/env bash
#for termux
if [ -d "/data/data/com.termux/files" ]; then
  export ROOT="/data/data/com.termux/files"
  export WORK_DIR="$ROOT/home"
  export HOME="$ROOT/home"
  if [ $SHELL == *zsh ]; then
    termux-fix-shebang ~/.zshenv
    termux-fix-shebang $ZDOTDIR/.zshrc
    termux-fix-shebang $ZDOTDIR/.zlogin
  fi
else
  sed -i 'XDG_RUNTIME_DIR="$ROOT\/usr\/tmp\/runtime-$USER"/XDG_RUNTIME_DIR="\/usr\/tmp\/runtime-$USER"' ~/.zshenv
fi

