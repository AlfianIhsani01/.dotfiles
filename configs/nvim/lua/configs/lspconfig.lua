require("nvchad.configs.lspconfig").defaults()

local lspconfig = require "lspconfig"
local servers = { "html", "cssls", "biome", "bash-language-server" }
vim.lsp.enable(servers)

lspconfig.rust_analyzer.setup({
    on_attach = function(client, bufnr)
        require'completion'.on_attach(client)
        vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
    end
})

lspconfig.biome.setup({
  -- Your Biome specific settings will go here
  -- For example, to enable formatting on save (requires Neovim 0.8+):
  on_attach = function(client, bufnr)
    if client.name == 'biome' then
      -- Enable formatting on save
      vim.api.nvim_create_autocmd('BufWritePre', {
        buffer = bufnr,
        callback = function()
          vim.lsp.buf.format({ bufnr = bufnr })
        end,
      })
    end
  end,
  settings = {
    -- You can add Biome-specific settings here, e.g.:
    biome = {
      linter = {
        enabled = true,
      },
      formatter = {
        enabled = true,
      },
    },
  },
})

