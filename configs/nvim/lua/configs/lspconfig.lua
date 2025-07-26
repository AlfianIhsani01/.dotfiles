require("nvchad.configs.lspconfig").defaults()

local lspconfig = require "lspconfig"
local servers = {
  "shellcheck",
  "shfmt",
  "bashls",
  "ccls",
  "clangd"
}
vim.lsp.enable(servers)


lspconfig.rust_analyzer.setup({
  on_attach = function(client, bufnr)
    require 'completion'.on_attach(client)
    vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
  end
})

lspconfig.ccls.setup {
  cmd = { "ccls" };
  filetypes = { "c", "cpp", "objc", "objcpp", "cuda" };
  root_marker = { "compile_commands.json", ".ccls", ".git" };
  workspace_required = true;
  init_options = {
    cache = {
      directory = ".ccls-cache";
    };
  }
}

-- local util = require 'lspconfig.util'
  -- settings = {
  --   Lua = {
  --     runtime = {
  --       version = 'LuaJIT',
  --     }
  --   }
  -- }

