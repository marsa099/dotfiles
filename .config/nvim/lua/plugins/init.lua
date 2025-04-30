return {
  {
    "stevearc/conform.nvim",
    event = "BufWritePre", -- uncomment for format on save
    opts = require "configs.conform",
  },
  {
    "williamboman/mason.nvim",
    cmd = "Mason",
    config = function()
      require("mason").setup()
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    after = "mason.nvim",
    config = function()
      require("mason-lspconfig").setup {
        ensure_installed = { "jsonls" },
      }
    end,
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
