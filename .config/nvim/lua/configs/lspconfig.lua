-- load defaults i.e lua_lsp
require("nvchad.configs.lspconfig").defaults()

local lspconfig = require "lspconfig"

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

--vim.lsp.set_log_level 'trace'
--  require('vim.lsp.log').set_format_func(vim.inspect)

-- Configure OmniSharp
lspconfig.omnisharp.setup {
  on_attach = nvlsp.on_attach,
  on_init = nvlsp.on_init,
  capabilities = nvlsp.capabilities,
  
  cmd = { "dotnet", "/home/martin/.local/share/nvim/mason/packages/omnisharp/libexec/OmniSharp.dll" },
  
  settings = {
    FormattingOptions = {
      EnableEditorConfigSupport = true,
      OrganizeImports = nil,
    },
    MsBuild = {
      LoadProjectsOnDemand = nil,
    },
    RoslynExtensionsOptions = {
      EnableAnalyzersSupport = nil,
      EnableImportCompletion = nil,
      AnalyzeOpenDocumentsOnly = nil,
    },
    Sdk = {
      IncludePrereleases = true,
    },
  },
  
  filetypes = { "cs", "vb" },
  root_dir = require("lspconfig.util").root_pattern("*.sln", "*.csproj", "omnisharp.json", "function.json"),
  
  on_new_config = function(new_config, _)
    new_config.cmd = { unpack(new_config.cmd or {}) }
    table.insert(new_config.cmd, "-z")
    vim.list_extend(new_config.cmd, { "--hostPID", tostring(vim.fn.getpid()) })
    table.insert(new_config.cmd, "DotNet:enablePackageRestore=false")
    vim.list_extend(new_config.cmd, { "--encoding", "utf-8" })
    table.insert(new_config.cmd, "--languageserver")
    
    local function flatten(tbl)
      local ret = {}
      for k, v in pairs(tbl) do
        if type(v) == "table" then
          for _, pair in ipairs(flatten(v)) do
            ret[#ret + 1] = k .. ":" .. pair
          end
        else
          ret[#ret + 1] = k .. "=" .. vim.inspect(v)
        end
      end
      return ret
    end
    
    if new_config.settings then
      vim.list_extend(new_config.cmd, flatten(new_config.settings))
    end
    
    new_config.capabilities = vim.deepcopy(new_config.capabilities)
    new_config.capabilities.workspace.workspaceFolders = false
  end,
  
  init_options = {},
}

