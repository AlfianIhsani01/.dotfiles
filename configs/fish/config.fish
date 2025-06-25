#!/data/data/com.termux/files/usr/bin/env fish
dirs_config       # Keep this function at top level
if status --is-interactive
  # Commands to run in interactive sessions can go here
  starship init fish | source
  zoxide init fish | source
  atuin init fish | source

  sed 's/$(ssh-agent -s)/(ssh-agent -c)/g' \
      ~/.config/src/alias.sh | source

end

if status --is-login
  ~/.config/fastfetch/startup.sh
end

auto-ls 1

set -gx EDITOR nvim
source $XDG_CONFIG_HOME/src/termux.sh

