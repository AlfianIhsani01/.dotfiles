require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set
-- local dmap= vim.keymap.del

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

-- Colemak-DH mappings for Neovim
map({'n', 'v'}, 'e', 'j', {noremap = true})
map({'n', 'v'}, 'u', 'k', {noremap = true})
map({'n', 'v'}, 'i', 'l', {noremap = true})
map({'n', 'v'}, 'n', 'h', {noremap = true})
-- Remap the keys we just overwrote
map({'n', 'v'}, 'j', 'e', {noremap = true})
map({'n', 'v'}, 'l', 'u', {noremap = true})
map({'n', 'v'}, 'k', 'i', {noremap = true})
map({'n', 'v'}, 'h', 'n', {noremap = true})

-- Extended movement
map({'n', 'v'}, 'N', 'J', {noremap = true})
map({'n', 'v'}, 'E', 'K', {noremap = true})
map({'n', 'v'}, 'I', 'L', {noremap = true})
map({'n', 'v'}, 'M', 'H', {noremap = true})

-- Other common remappings
map({'n', 'v'}, 'f', 't', {noremap = true})
map({'n', 'v'}, 'F', 'T', {noremap = true})
map({'n', 'v'}, 't', 'j', {noremap = true})
map({'n', 'v'}, 'T', 'J', {noremap = true})

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")

