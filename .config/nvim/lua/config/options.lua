-- Hide nvim start screen
vim.opt.shortmess:append("I")

-- Relative + current line number
vim.opt.number = true
vim.opt.relativenumber = true

-- Make cursor centered while scrolling up/down.
-- Changing 999 to e.g. 10 would make scrolling keep 10 lines above/below cursor
vim.opt.scrolloff = 999

-- Share clipboard between nvim and rest of the system
vim.opt.clipboard = "unnamedplus"

-- Needed to make smartcase work apparently
vim.opt.ignorecase = true

-- Smart case for search commands (only case sensitive when uppercase is used)
vim.opt.smartcase = true

-- Hide ~ on empty lines
vim.opt.fillchars = { eob = " " }

-- Spaces instead of tabs
vim.opt.expandtab = true

-- Every indent is shown as 4 spaces
vim.opt.tabstop = 4

-- Manual indent by 4 spaces
vim.opt.shiftwidth = 4

-- Enable project-specific configuration files (.nvim.lua, .nvimrc, .exrc)
-- This allows each project to have its own settings that override global config
vim.opt.exrc = true

-- Security protection for project-specific configs
-- Restricts dangerous operations (shell commands, autocmds, etc.) in untrusted project files
-- Safe operations like setting variables (vim.g.disable_autoformat) are still allowed
vim.opt.secure = true
