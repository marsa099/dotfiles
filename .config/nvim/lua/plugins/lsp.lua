return {
  {
    "neovim/nvim-lspconfig",
    config = function()
      -- load defaults i.e lua_lsp
      require("nvchad.configs.lspconfig").defaults()

      local lspconfig = require "lspconfig"
      local nvlsp = require "nvchad.configs.lspconfig"

      -- LSP servers with default config
      local servers = { "html", "cssls", "bicep", "jsonls" }

      for _, lsp in ipairs(servers) do
        lspconfig[lsp].setup {
          on_attach = nvlsp.on_attach,
          on_init = nvlsp.on_init,
          capabilities = nvlsp.capabilities,
        }
      end

      -- TypeScript server with default config
      lspconfig.ts_ls.setup {
        on_attach = nvlsp.on_attach,
        on_init = nvlsp.on_init,
        capabilities = nvlsp.capabilities,
      }

      -- Tailwind CSS with custom settings
      lspconfig.tailwindcss.setup {
        capabilities = nvlsp.capabilities,
        on_attach = nvlsp.on_attach,
        settings = {
          tailwindCSS = {
            experimental = {
              classRegex = {
                { "cva\\(([^)]*)\\)", "[\"'`]([^\"'`]*).*?[\"'`]" },
                { "cx\\(([^)]*)\\)", "(?:'|\"|`)([^']*)(?:'|\"|`)" },
              },
            },
          },
        },
      }

      -- OmniSharp setup with custom settings (mason manages installation)
      -- NOTE: For .NET Framework projects, you may need to override cmd with:
      -- cmd = { "/opt/omnisharp-mono/run", "--languageserver", "--hostPID", tostring(vim.fn.getpid()) }
      -- Mason installs OmniSharp with capital letters
      local omnisharp_path = vim.fn.exepath "OmniSharp"
      if omnisharp_path == "" then
        omnisharp_path = vim.fn.exepath "omnisharp"
      end
      if omnisharp_path ~= "" then
        lspconfig.omnisharp.setup {
          -- Let lspconfig handle the command arguments to avoid duplicates
          cmd = { omnisharp_path },
        on_attach = nvlsp.on_attach,
        on_init = nvlsp.on_init,
        capabilities = nvlsp.capabilities,
        root_dir = function(fname)
          return lspconfig.util.root_pattern("*.sln", "*.csproj", "omnisharp.json", "function.json")(fname)
            or lspconfig.util.find_git_ancestor(fname)
        end,
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
    end,
  },
}

