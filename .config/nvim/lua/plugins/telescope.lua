return {
  {
    "nvim-telescope/telescope.nvim",
    opts = function()
      -- Get NvChad's base telescope config
      local base_config = require "nvchad.configs.telescope"
      
      -- Add ui-select extension to NvChad's extensions
      if not base_config.extensions then
        base_config.extensions = {}
      end
      base_config.extensions["ui-select"] = {
        require("telescope.themes").get_dropdown {},
      }
      
      return base_config
    end,
  },
  {
    "nvim-telescope/telescope-ui-select.nvim",
    dependencies = { "nvim-telescope/telescope.nvim" },
    config = function()
      -- Load the ui-select extension
      require("telescope").load_extension "ui-select"
    end,
  },
}