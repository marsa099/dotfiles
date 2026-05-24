vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Load core options early
require("config.options")
require("config.keymaps")
require("config.nuget-check")

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
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

local function read_theme_mode()
	local f = io.open(vim.fn.expand("~/.config/theme_mode"), "r")
	if not f then return "dark" end
	local mode = (f:read("*l") or ""):gsub("%s+", "")
	f:close()
	return (mode == "light") and "light" or "dark"
end

vim.cmd.colorscheme("custom-theme-" .. read_theme_mode())
