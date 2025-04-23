-- load defaults i.e lua_lsp
require("nvchad.configs.lspconfig").defaults()

local lspconfig = require "lspconfig"

-- EXAMPLE
local servers = { "html", "cssls", "bicep", "ts_ls" }
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
lspconfig.ts_ls.setup {
  on_attach = nvlsp.on_attach,
  on_init = nvlsp.on_init,
  capabilities = nvlsp.capabilities,
}

local function is_framework_project()
  local csproj_paths = vim.fn.glob("**/*.csproj", true, true)
  for _, path in ipairs(csproj_paths) do
    local file = io.open(path, "r")
    if file then
      for line in file:lines() do
        if line:match "TargetFrameworkVersion" then
          file:close()
          vim.notify("Detected .NET Framework in: " .. path, vim.log.levels.INFO)
          return true
        end
      end
      file:close()
    end
  end
  return false
end

if is_framework_project() then
  vim.notify("Using OmniSharp (Mono) for .NET Framework project", vim.log.levels.INFO)
  lspconfig.omnisharp.setup {
    cmd = {
      "/opt/omnisharp-mono/run",
      "--languageserver",
      "--hostPID",
      tostring(vim.fn.getpid()),
    },
    on_attach = nvlsp.on_attach,
    on_init = nvlsp.on_init,
    capabilities = nvlsp.capabilities,
  }
else
  vim.notify("Using OmniSharp (Core) for .NET Core project", vim.log.levels.INFO)
  lspconfig.omnisharp.setup {
    cmd = { "omnisharp", "--languageserver", "--hostPID", tostring(vim.fn.getpid()) },
    -- cmd = {
    --   vim.fn.stdpath("data") .. "/mason/bin/omnisharp",
    --   "--languageserver",
    --   "--hostPID",
    --   tostring(vim.fn.getpid()),
    -- },
    -- cmd = { "dotnet", "/home/martin/.local/share/nvim/mason/packages/omnisharp/omnisharp" },
    on_attach = nvlsp.on_attach,
    on_init = nvlsp.on_init,
    capabilities = nvlsp.capabilities,
    settings = {
      FormattingOptions = {
        -- Enables support for reading code style, naming convention and analyzer
        -- settings from .editorconfig.
        EnableEditorConfigSupport = nil,
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
        EnableAnalyzersSupport = nil,
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
end

lspconfig.bicep.setup {
  cmd = { "dotnet", "/usr/local/bin/bicep-langserver/Bicep.LangServer.dll" },
}
