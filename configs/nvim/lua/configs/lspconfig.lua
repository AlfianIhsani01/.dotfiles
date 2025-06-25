require("nvchad.configs.lspconfig").defaults()

local lspconfig = require "lspconfig"
local servers = { "shellcheck", "biome", "bashls" }
vim.lsp.enable(servers)


local util = require 'lspconfig.util'
vim.lsp.config('biome', {
  cmd = { "biome", "lsp-proxy" },
  filetypes = { "astro", "css", "graphql", "html", "javascript", "javascriptreact", "json", "jsonc", "svelte", "typescript", "typescript.tsx", "typescriptreact", "vue" },
  workspace_required = true,
  root_dir = function(bufnr, on_dir)
    local fname = vim.api.nvim_buf_get_name(bufnr)
    local root_files = { 'biome.json', 'biome.jsonc' }
    root_files = util.insert_package_json(root_files, 'biome', fname)
    local root_dir = vim.fs.dirname(vim.fs.find(root_files, { path = fname, upward = true })[1])
    on_dir(root_dir)
  end,
})

lspconfig.rust_analyzer.setup({
  on_attach = function(client, bufnr)
    require 'completion'.on_attach(client)
    vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
  end
})
