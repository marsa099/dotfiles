vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Load core options early
require("config.options")
require("config.keymaps")

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Setup lazy.nvim (only on first run)
if not package.loaded["lazy"] then
  require("lazy").setup("plugins", {
    defaults = {
      lazy = true,
    },
    install = {
      colorscheme = { "default" },
    },
    checker = {
      enabled = false,
    },
    change_detection = {
      enabled = true,
      notify = false,
    },
    performance = {
      rtp = {
        disabled_plugins = {
          "netrwPlugin",
        },
      },
    },
  })
end

-- Setup reload after plugins are loaded
vim.defer_fn(function()
  local ok, reload = pcall(require, "utils.reload")
  if ok then
    reload.setup()
  end
end, 100)
