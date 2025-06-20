require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set
-- local dmap= vim.keymap.del

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

-- reserved keys
map("", "s", "<Nop>")
map("", "S", "<Nop>")
map("", "o", "<Nop>")
map("", "O", "<Nop>")

-- up, down, left, right
map("", "u", "k")
map("", "U", "5k")
map("", "e", "j")
map("", "E", "5j")
map("", "n", "h")
map("", "N", "^")
map("", "i", "l")
map("", "I", "$")

map("n", "<C-u>", 'line(".")>1 ? ":m .-2<CR>" : ""', { expr = true, silent = true })
map("n", "<C-e>", 'line(".")<line("$") ? ":m .+1<CR>" : ""', { expr = true, silent = true })
map("v", "<C-u>", 'line(".")>1 ? ":m \'<-2<CR>gv" : ""', { expr = true, silent = true })
map("v", "<C-e>", 'line(".")<line("$") ? ":m \'>+1<CR>gv" : ""', { expr = true, silent = true })

map("c", "<C-u>", "<Up>")
map("c", "<C-e>", "<Down>")

-- word navigation keys
map("", "m", "e")
map("", "M", "E")

-- insert mode keys
map("n", "k", function() return #vim.fn.getline(".") == 0 and '"_cc' or "i" end, { expr = true })
map("v", "k", "i")
map("v", "K", "I")
map("", "h", "o")
map("", "H", "O")

map("n", "<C-n>", "I")
map("i", "<C-n>", "<Esc>I")
map("n", "<C-i>", "A")
map("i", "<C-i>", "<Esc>A")

-- redo, undo
map("n", "l", "u")
map("n", "L", "<C-r>")

-- yank, paste
map("x", "p", '"_dP')
map("x", "P", '"_dp')

map({ "n", "v" }, "x", '"_x')

map("n", "dw", 'vb"_d')
map("n", "cw", 'vb"_c')

-- search keys
map("n", "-", "'Nn'[v:searchforward]", { expr = true })
map("x", "-", "'Nn'[v:searchforward]", { expr = true })
map("o", "-", "'Nn'[v:searchforward]", { expr = true })
map("n", "=", "'nN'[v:searchforward]", { expr = true })
map("x", "=", "'nN'[v:searchforward]", { expr = true })
map("o", "=", "'nN'[v:searchforward]", { expr = true })

map("v", "-", function() require("utils").search(false) end)
map("v", "=", function() require("utils").search(true) end)

-- tab management
map({ "n", "v" }, "tt", ":tabe<CR>", { silent = true })
map({ "n", "v" }, "tT", ":tab split<CR>", { silent = true })
map({ "n", "v" }, "tn", ":-tabnext<CR>", { silent = true })
map({ "n", "v" }, "ti", ":+tabnext<CR>", { silent = true })
map({ "n", "v" }, "tN", ":-tabmove<CR>", { silent = true })
map({ "n", "v" }, "tI", ":+tabmove<CR>", { silent = true })

-- other keys
map("n", "<C-S-M-s>", ":up<CR>", { silent = true })
map("i", "<C-S-M-s>", "<Esc>:up<CR>a", { silent = true })
map("v", "<C-S-M-s>", "<Esc>:up<CR>", { silent = true })

map("", "<C-a>", "ggVG$")
map({ "i", "v" }, "<C-a>", "<Esc>ggVG$")

map("", "<C-r>", ":filetype detect<CR>", { silent = true })
map("i", "<C-r>", "<Esc>:filetype detect<CR>a", { silent = true })

map("", "<C-->", "<C-a>")
map({ "i", "v" }, "<C-->", "<Esc><C-a>a")
map("", "<C-=>", "<C-x>")
map({ "i", "v" }, "<C-=>", "<Esc><C-x>a")

map("n", "<leader>`", function() require("lazy").profile() end)
