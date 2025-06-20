#!/data/data/com.termux/files/usr/bin/env fish
dirs_config       # Keep this function at top level
function starship_transient_prompt_func
  starship module line_break
  starship module custom.dot
  starship module git_branch
  starship module character
end
enable_transience
set -gx EDITOR nvim
source $XDG_CONFIG_HOME/src/termux.sh

