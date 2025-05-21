-- This file needs to have same structure as nvconfig.lua 
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
-- Please read that file to know all available options :( 

---@type ChadrcConfig
local M = {}

M.base46 = {
	theme = "bearded-arc",

	hl_override = {
		Comment = { italic = false },
		["@comment"] = { italic = true },
	},
}

M.nvdash = {
  load_on_startup = true,

  header = {
" ┳━━━┓┏━━━┓┏━━━┓▗▄▖ ▗▄▖▄▄▗▄▄▄▄▄▄▄ ",
" ┃   ┃┃   ┃┃   ┃ █   ▐▌ █  █  █ ",
" ┃   ┃┣━━━┛┃   ┃ █   ▐▌ █  █  █ ",
" ┃   ┃┃    ┃   ┃ █   ▐▌ █  █  █ ",
" ┻   ┻┗━━━┛┗━━━┛▝▀▀    ▀▀▝▀  ▀  ▀▘",
"                                 "
                                  },

}
M.ui = {
  -- statusline = {
  --   separator_style = "block",
  --   theme = "minimal"
  -- },
  tabufline = {
    lazyload = false,
  },
  transparency = true
}

return M
