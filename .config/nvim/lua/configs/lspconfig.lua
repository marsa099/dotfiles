-- load defaults i.e lua_lsp
require("nvchad.configs.lspconfig").defaults()

local lspconfig = require "lspconfig"
local omnisharp_ext = require("omnisharp_extended")

-- EXAMPLE
local servers = { "html", "cssls" }
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
  --cmd = { "omnisharp", "--languageserver", "--hostPID", tostring(vim.fn.getpid()) },
  -- cmd = {
  --   vim.fn.stdpath("data") .. "/mason/bin/omnisharp",
  --   "--languageserver",
  --   "--hostPID",
  --   tostring(vim.fn.getpid()),
  -- },
  cmd = { "dotnet", "/home/martin/.local/share/nvim/mason/packages/omnisharp/omnisharp" },
  on_attach = function(client, bufnr)
    nvlsp.on_attach(client, bufnr)
    -- Patcha handlers
    client.handlers["textDocument/definition"] = omnisharp_ext.handler
    client.handlers["textDocument/typeDefinition"] = omnisharp_ext.handler
    client.handlers["textDocument/implementation"] = omnisharp_ext.handler
  end,
  on_init = nvlsp.on_init,
  capabilities = nvlsp.capabilities,
  settings = {
    FormattingOptions = {
          -- Enables support for reading code style, naming convention and analyzer
          -- settings from .editorconfig.
          EnableEditorConfigSupport = true,
          -- Specifies whether 'using' directives should be grouped and sorted during
          -- document formatting.
          OrganizeImports = true,
        },
        MsBuild = {
          -- If true, MSBuild project system will only load projects for files that
          -- were opened in the editor. This setting is useful for big C# codebases
          -- and allows for faster initialization of code navigation features only
          -- for projects that are relevant to code that is being edited. With this
          -- setting enabled OmniSharp may load fewer projects and may thus display
          -- incomplete reference lists for symbols.
          LoadProjectsOnDemand = nil,
        },
        RoslynExtensionsOptions = {
          -- Enables support for roslyn analyzers, code fixes and rulesets.
          EnableAnalyzersSupport = true,
          -- Enables support for showing unimported types and unimported extension
          -- methods in completion lists. When committed, the appropriate using
          -- directive will be added at the top of the current file. This option can
          -- have a negative impact on initial completion responsiveness,
          -- particularly for the first few completion sessions after opening a
          -- solution.
          EnableImportCompletion = true,
          -- Only run analyzers against open files when 'enableRoslynAnalyzers' is
          -- true
          AnalyzeOpenDocumentsOnly = nil,
        },
        Sdk = {
          -- Specifies whether to include preview versions of the .NET SDK when
          -- determining which version to use for project loading.
          IncludePrereleases = true,
        },
      },
  }
