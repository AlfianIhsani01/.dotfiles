-- This file needs to have same structure as nvconfig.lua
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
-- Please read that file to know all available options :(

---@type ChadrcConfig
local M = {}

M.base46 = {
  theme = "ayu_dark",

  -- hl_override = {
  -- 	Comment = { italic = false },
  -- 	["@comment"] = { italic = true },
  -- },
}

M.nvdash = {
  load_on_startup = true,

  header = {
    " ┳━━━┓┏━━━┓┏━━━┓▗▄▖ ▗▄▖▄▄▗▄▄▄▄▄▄▄ ",
    " ┃   ┃┃   ┃┃   ┃ █   ▐▌ █  █  █ ",
    " ┃   ┃┣━━━┛┃   ┃ █   ▐▌ █  █  █ ",
    " ┃   ┃┃    ┃   ┃ █   ▐▌ █  █  █ ",
    " ┻   ┻┗━━━┛┗━━━┛▝▀▀    ▀▀▝▀  ▀  ▀▘",
    "                                  "
  },

}
M.ui = {
  statusline = {
    custom_sl = true,
    override_statusline_fn =function ()
      require("configs.lualine")
    end
    -- theme = "minimal",
    -- separator_style = "block",
    -- order = { "mode", "git", "%=", "lsp_msg", "%=", "diagnostics", "lsp", "cursor" },
  },
  tabufline = {
    lazyload = true,
  },
  transparency = true
}

return M
