return {
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
}