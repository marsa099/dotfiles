return {
  -- Disable NvChad defaults for plugins we want full control over
  { "stevearc/conform.nvim", enabled = false },
  {
    "github/copilot.vim",
    lazy = false,
  },
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    dependencies = {
      { "github/copilot.vim" }, -- or zbirenbaum/copilot.lua
      { "nvim-lua/plenary.nvim", branch = "master" }, -- for curl, log and async functions
    },
    build = "make tiktoken", -- Only on MacOS or Linux
    opts = {
      -- See Configuration section for options
    },
    -- See Commands section for default commands if you want to lazy load on them
    lazy = false,
  },
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    opts = {
      -- NvChad base config: formatters_by_ft = { lua = { "stylua" } }
      -- Extended with user formatters
      formatters_by_ft = {
        lua = { "stylua" },
        csharp = { "csharpier" },
        javascript = { "prettier" },
        typescript = { "prettier" },
        javascriptreact = { "prettier" },
        typescriptreact = { "prettier" },
        svelte = { "prettier" },
        vue = { "prettier" },
        css = { "prettier" },
        html = { "prettier" },
        less = { "prettier" },
        scss = { "prettier" },
        markdown = { "prettier" },
        json = { "prettier" },
        yaml = { "prettier" },
      },
      
      format_after_save = {
        timeout_ms = 500,
        lsp_fallback = true,
      },
    },
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "mason.nvim" },
    opts = {
      ensure_installed = { 
        "html", 
        "cssls", 
        "ts_ls", 
        "jsonls", 
        "tailwindcss",
        "bicep",
        "omnisharp"
        -- Note: all LSPs now managed by mason
      },
    },
  },
  -- These are some examples, uncomment them if you want to see them work!
  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },
  {
    "nvim-tree/nvim-tree.lua",
    opts = function()
      local default_config = require "nvchad.configs.nvimtree"
      local custom_config = {
        view = {
          adaptive_size = true,
        },
        -- Add more overrides here if needed
      }

      -- Deep-merge between NVChad default config and my config
      return vim.tbl_deep_extend("force", default_config, custom_config)
    end,
  },
  {
    "nvim-telescope/telescope-ui-select.nvim",
    dependencies = { "nvim-telescope/telescope.nvim" },
    config = function()
      local telescope = require "telescope"

      telescope.setup {
        extensions = {
          ["ui-select"] = {
            require("telescope.themes").get_dropdown {},
          },
        },
      }

      telescope.load_extension "ui-select"
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "vim",
        "lua",
        "vimdoc",
        "html",
        "css",
        "c_sharp",
      },
    },
  },
  {
    "Hoffs/omnisharp-extended-lsp.nvim",
    lazy = true,
    ft = { "cs" },
  },
  {
    "rmagatti/auto-session",
    lazy = false,

    -- enables autocomplete for opts
    -- @module "auto-session"
    -- @type AutoSession.Config
    opts = {
      suppressed_dirs = { "~/", "~/Projects", "~/Downloads", "/" },
      -- log_level = 'debug',
    },
  },
}
