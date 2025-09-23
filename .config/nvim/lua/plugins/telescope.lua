return {
  {
    "nvim-telescope/telescope.nvim",
    opts = function()
      -- Get NvChad's base telescope config
      local base_config = require "nvchad.configs.telescope"

      if not base_config.defaults then
        base_config.defaults = {}
      end
      if not base_config.defaults.mappings then
        base_config.defaults.mappings = {}
      end
      if not base_config.defaults.mappings.i then
        base_config.defaults.mappings.i = {}
      end
      local actions = require "telescope.actions"
      base_config.defaults.mappings.i["<C-j>"] = actions.move_selection_next
      base_config.defaults.mappings.i["<C-k>"] = actions.move_selection_previous

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
  {
    "nvim-telescope/telescope-live-grep-args.nvim",
    dependencies = { "nvim-telescope/telescope.nvim" },
    config = function()
      local telescope = require("telescope")
      telescope.setup {
        extensions = {
          live_grep_args = {
            auto_quoting = false, -- Disable auto-quoting to allow ripgrep flags
          }
        }
      }
      telescope.load_extension "live_grep_args"
    end,
  },
}
