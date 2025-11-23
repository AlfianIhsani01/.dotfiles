-- This file needs to have same structure as nvconfig.lua
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
-- Please read that file to know all available options :(

---@type ChadrcConfig
local M = {}

M.base46 = {
  theme = "falcon",

  -- hl_override = {
  -- 	Comment = { italic = false },
  -- 	["@comment"] = { italic = true },
  -- },
}

-- M.nvdash = { load_on_startup = true }
M.ui = {
  statusline = {
    theme = "minimal",
    separator_style = "arrow",
    order = { "mode", "git", "%=", "lsp_msg", "%=", "diagnostics", "lsp", "cursor" },
  },

  tabufline = {
    lazyload = true,
  },
  transparency = false,
}

return M
