#!/data/data/com.termux/files/usr/bin/nv zsh

# History
HISTFILE=~/.dotfiles/configs/zsh/dot-zsh_history
HISTSIZE=2000
SAVEHIST=1000
setopt SHARE_HISTORY
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY


config_shortcut() {
  folder=$1
  if [[ $XDG_CONFIG_HOME != 0 ]]; then
    config_path=$XDG_CONFIG_HOME
  else
    config_path=$HOME/.config
  fi
  if [[ $folder != 0 ]]; then
    cd $config_path/$folder
  else
    cd $config_path
  fi
}

