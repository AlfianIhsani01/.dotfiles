#!/data/data/com.termux/files/usr/bin/env bash
fix_linux_shebang() {

if [ $# = 0 -o "$1" = "-h" ]; then
        echo 'usage: fix-linux-shebang <files>'
        echo 'Rewrite shebangs in specified files for running under regular Linux,'
        echo 'which is done by rewriting #\!@TERMUX_PREFIX@/bin/binary to #!/bin/binary.'
        exit 1
fi

for file in "$@"; do
        sed -i -E "1 s@^#\!@TERMUX_PREFIX@/bin/(.*)@#!/bin/\1@" "$(realpath "${file}")"
done
}
#for termux
if [ -d "/data/data/com.termux/files" ]; then
  export ROOT="/data/data/com.termux/files"
  export HOME="$ROOT/home"
  if [ $SHELL == *zsh ]; then
    termux-fix-shebang ~/.zshenv
    termux-fix-shebang $ZDOTDIR/.zshrc
    termux-fix-shebang $ZDOTDIR/.zlogin
  fi
else
  fix-linux-shebang ~/.zshenv
  fix-linux-shebang $ZDOTDIR/.zshrc
  fix-linux-shebang $ZDOTDIR/.zlogin
  sed -i '"$ROOT\/usr\/tmp\/runtime-$UID"/"\/usr\/tmp\/runtime-$UID"' ~/.zshenv
  sed -i '"$ROOT\/usr\/tmp\/runtime-$UID"/"\/usr\/tmp\/runtime-$UID"' ~/.config/fish/functions/xdg_dirs.fish
fi

