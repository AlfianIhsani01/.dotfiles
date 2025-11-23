require "nvchad.mappings"

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map({ "", "v", "i" }, "bp", "<ESC>", { noremap = false })

-- reserved keys
map("", "s", "<Nop>")
map("", "S", "<Nop>")
-- map("", "j", "<Nop>")
map("n", "b", "<Nop>")
map("", "B", "<Nop>")

map("n", "j", "J" ,{ desc ="join line"})
-- up, down, left, right
map("", "u", "k")
map("", "U", "5k")
map("", "e", "j")
map("", "E", "5j")
map("", "n", "h")
map("", "N", "0")
map("", "i", "l")
map("", "I", "$")

map("n", "<C-u>", 'line(".")>1 ? ":m .-2<CR>" : ""', { expr = true, silent = true })
map("n", "<C-e>", 'line(".")<line("$") ? ":m .+1<CR>" : ""', { expr = true, silent = true })
map("v", "<C-u>", 'line(".")>1 ? ":m \'<-2<CR>gv" : ""', { expr = true, silent = true })
map("v", "<C-e>", 'line(".")<line("$") ? ":m \'>+1<CR>gv" : ""', { expr = true, silent = true })

map("c", "<C-u>", "<Up>")
map("c", "<C-e>", "<Down>")

-- word navigation keys
map("n", "o", "e")
map("n", "O", "E")
map("n", "m", "b")
map("n", "M", "B")

-- insert mode keys
map("n", "k", function()
  return #vim.fn.getline "." == 0 and '"_cc' or "i"
end, { expr = true })
map("v", "k", "xi")
map("v", "K", "xI")
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
map("n", "=", "'Nn'[v:searchforward]", { expr = true })
map("x", "=", "'Nn'[v:searchforward]", { expr = true })
map("o", "=", "'Nn'[v:searchforward]", { expr = true })
map("n", "-", "'nN'[v:searchforward]", { expr = true })
map("x", "-", "'nN'[v:searchforward]", { expr = true })
map("o", "-", "'nN'[v:searchforward]", { expr = true })

map("v", "=", function()
  require("utils").search(false)
end)
map("v", "-", function()
  require("utils").search(true)
end)

-- tab management
map({ "n", "v" }, "tt", ":tabe<CR>", { silent = true })
map({ "n", "v" }, "tT", ":tab split<CR>", { silent = true })
map({ "n", "v" }, "tn", ":-tabnext<CR>", { silent = true })
map({ "n", "v" }, "ti", ":+tabnext<CR>", { silent = true })
map({ "n", "v" }, "tN", ":-tabmove<CR>", { silent = true })
map({ "n", "v" }, "tI", ":+tabmove<CR>", { silent = true })

map("n", "<C-j>", "<cmd>set wrap!<CR>", { desc = "toggle line wrap", silent = true })
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
map("n", "<leader>`", function()
  require("lazy").profile()
end, { desc = "View lazy profile" })

-- open Nvimtree window
map({ "n", "x" }, "<C-m>", "<cmd>NvimTreeToggle<CR>")
-- NvimTree mappings
local function my_on_attach(bufnr)
  local api = require "nvim-tree.api"

  local function opts(desc)
    return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
  end

  -- BEGIN_DEFAULT_ON_ATTACH
  map("n", "<CR>",           api.node.open.edit,                 opts "Open")
  map("n", "<CR>",           api.tree.close,                     opts "Close")
  map("n", "g",              api.tree.change_root_to_node,       opts "CD")
  map("n", "a",              api.tree.change_root_to_parent,     opts "Up")
  map("n", "j",              api.node.open.replace_tree_buffer,  opts "Open: In Place")
  map("n", "k",              api.node.open.no_window_picker,     opts "Open: No Window Picker")
  map("n", "K",              api.node.open.tab,                  opts "Open: New Tab")
  map("n", "h",              api.node.open.vertical,             opts "Open: Vertical Split")
  map("n", "H",              api.node.open.horizontal,           opts "Open: Horizontal Split")
  map("n", "<Tab>",          api.node.open.preview,              opts "Open Preview")
  map("n", 'o',              api.tree.expand_all,                opts "Expand All")
  map("n", "O",              api.tree.collapse_all,              opts "Collapse All")
  map("n", "z",              api.tree.reload,                    opts "Refresh")
  map("n", 'U',              api.node.navigate.parent,           opts "Parent Directory")
  map("n", "E",              api.node.navigate.parent_close,     opts "Close Directory")
  map("n", "c",              api.fs.create,                      opts "Create File Or Directory")
  map("n", "yy",             api.fs.copy.node,                   opts "Copy")
  map("n", "p",              api.fs.paste,                       opts "Paste")
  map("n", "v",              api.fs.cut,                         opts "Cut")
  map("n", "X",              api.fs.remove,                      opts "Delete")
  map("n", "x",              api.fs.trash,                       opts "Trash")
  map("n", "rr",             api.fs.rename,                      opts "Rename")
  map("n", "rk",             api.fs.rename_basename,             opts "Rename: Basename")
  map("n", "rK",             api.fs.rename_full,                 opts "Rename: Full Path")
  map("n", "rf",             api.fs.rename_sub,                  opts "Rename: Omit Filename")
  map("n", "yn",             api.fs.copy.filename,               opts "Copy Name")
  map("n", "ye",             api.fs.copy.basename,               opts "Copy Basename")
  map("n", "yp",             api.fs.copy.absolute_path,          opts "Copy Absolute Path")
  map("n", "yr",             api.fs.copy.relative_path,          opts "Copy Relative Path")
  map("n", "m",              api.marks.toggle,                   opts "Toggle Bookmark")
  map("n", "bd",             api.marks.bulk.delete,              opts "Delete Bookmarked")
  map("n", "bc",             api.marks.bulk.trash,               opts "Trash Bookmarked")
  map("n", "bm",             api.marks.bulk.move,                opts "Move Bookmarked")
  map("n", ".",              api.node.run.cmd,                   opts "Run Command")
  map("n", "q",              api.node.run.system,                opts "Run System")
  map("n", "?",              api.tree.toggle_help,               opts "Help")
  map("n", "/",              api.node.show_info_popup,           opts "Info")
  map("n", "i",              api.node.navigate.sibling.next,     opts "Next Sibling")
  map("n", "n",              api.node.navigate.sibling.prev,     opts "Previous Sibling")
  map("n", "N",              api.node.navigate.sibling.first,    opts "First Sibling")
  map("n", "I",              api.node.navigate.sibling.last,     opts "Last Sibling")
  map("n", "ti",             api.tree.toggle_gitignore_filter,   opts "Toggle Filter: Git Ignore")
  map("n", "t.",             api.tree.toggle_git_clean_filter,   opts "Toggle Filter: Git Clean")
  map("n", "tb",             api.tree.toggle_no_buffer_filter,   opts "Toggle Filter: No Buffer")
  map("n", "td",             api.tree.toggle_hidden_filter,      opts "Toggle Filter: Dotfiles")
  map("n", "to",             api.node.open.toggle_group_empty,   opts "Toggle Group Empty")
  map("n", "tm",             api.tree.toggle_no_bookmark_filter, opts "Toggle Filter: No Bookmark")
  map("n", "th",             api.tree.toggle_custom_filter,      opts "Toggle Filter: Hidden")
  map("n", "[c",             api.node.navigate.git.prev,         opts "Prev Git")
  map("n", "]c",             api.node.navigate.git.next,         opts "Next Git")
  map("n", "]e",             api.node.navigate.diagnostics.next, opts "Next Diagnostic")
  map("n", "[e",             api.node.navigate.diagnostics.prev, opts "Prev Diagnostic")
  map("n", "<BS>",           api.live_filter.clear,              opts "Live Filter: Clear")
  map("n", "w",              api.live_filter.start,              opts "Live Filter: Start")
  map("n", "s",              api.tree.search_node,               opts "Search")
  map("n", "<2-LeftMouse>",  api.node.open.edit,                 opts "Open")
  map("n", "<2-RightMouse>", api.tree.change_root_to_node,       opts "CD")
  -- END_DEFAULT_ON_ATTACH
  -- -- copy default mappings here from defaults in next section
  -- vim.keymap.set("n", "<C-]>", api.tree.change_root_to_node, opts("CD"))
  -- vim.keymap.set("n", "<C-e>", api.node.open.replace_tree_buffer, opts("Open: In Place"))
  -- ---
  -- -- OR use all default mappings
  -- api.config.mappings.default_on_attach(bufnr)
  --
  -- -- remove a default
  -- vim.keymap.del("n", "<C-]>", { buffer = bufnr })
  --
  -- -- override a default
  -- vim.keymap.set("n", "<C-e>", api.tree.reload, opts("Refresh"))
  --
  -- -- add your mappings
  -- vim.keymap.set("n", "?", api.tree.toggle_help, opts("Help"))
  ---
end

require("nvim-tree").setup {
  ---
  on_attach = my_on_attach,
  ---
}
