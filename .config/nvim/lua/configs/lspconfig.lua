-- load defaults i.e lua_lsp
require("nvchad.configs.lspconfig").defaults()

local lspconfig = require "lspconfig"
local omnisharp_ext = require("omnisharp_extended")

-- EXAMPLE
local servers = { "html", "cssls", }
local nvlsp = require "nvchad.configs.lspconfig"

-- lsps with default config
for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup {
    on_attach = nvlsp.on_attach,
    on_init = nvlsp.on_init,
    capabilities = nvlsp.capabilities,
  }
end

-- configuring single server, example: typescript
-- lspconfig.ts_ls.setup {
--   on_attach = nvlsp.on_attach,
--   on_init = nvlsp.on_init,
--   capabilities = nvlsp.capabilities,
-- }

lspconfig.omnisharp.setup {
  cmd = { "omnisharp", "--languageserver", "--hostPID", tostring(vim.fn.getpid()) },
  on_attach = function(client, bufnr)
    nvlsp.on_attach(client, bufnr)
    -- Patcha handlers
    client.handlers["textDocument/definition"] = omnisharp_ext.handler
    client.handlers["textDocument/typeDefinition"] = omnisharp_ext.handler
    client.handlers["textDocument/implementation"] = omnisharp_ext.handler
  end,
  on_init = nvlsp.on_init,
  capabilities = nvlsp.capabilities,
}
