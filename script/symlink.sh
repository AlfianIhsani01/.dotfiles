symlink_tools() {
  if command -v stow >/dev/null 2>&1; then
    echo "(1)copy or use (2)stow"
    read -r crs
    if [[ $crs == 2 ]]; then
      echo "stow used"
    else
      echo "cp used"
  else
    echo "cp used"
  fi
}

check_symlink() {
  local symlist=()
  for list in $DOTHOME/configs/*; do
    ls
  done
  
}
symlink_do() {
# symlink list
ln -s $HOME/.dotfiles/other/zshenv $HOME/.zshenv
ln -s $HOME/.dotfiles/zsh ${XDG_CONFIG_HOME:-$HOME/.config}
ln -s $HOME/.dotfiles/nvim ${XDG_CONFIG_HOME:-$HOME/.config}
ln -s $HOME/.dotfiles/tmux ${XDG_CONFIG_HOME:-$HOME/.config}
ln -s $HOME/.dotfiles/other/starship.toml ${XDG_CONFIG_HOME:-$HOME/.config}
ln -s $HOME/.dotfiles/atuin ${XDG_CONFIG_HOME:-$HOME/.config}

# Termux
if [ -d /data/data/com.termux/files ]; then
   ln -s $HOME/.dotfiles/termux $TERMUX__HOME/.termux
fi  
  
