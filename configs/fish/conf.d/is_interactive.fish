#!/usr/bin/env fish
if status --is-interactive
  # Commands to run in interactive sessions can go here
  starship init fish | source
  zoxide init fish | source
  atuin init fish | source

  sed 's/$(ssh-agent -s)/(ssh-agent -c)/g' \
      ~/.config/src/alias.sh | source

end

if status --is-login
  source ~/.config/fastfetch/startup.sh
  echo \n
end
