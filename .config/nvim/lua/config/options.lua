-- Hide nvim start screen
vim.opt.shortmess:append("I")

-- Relative + current line number
vim.opt.number = true
vim.opt.relativenumber = true

-- Share clipboard between nvim and rest of the system
vim.opt.clipboard = "unnamedplus"

-- Smart case for search commands (only case sensitive when uppercase is used)
vim.opt.smartcase = true

-- Hide ~ on empty lines
vim.opt.fillchars = { eob = " " }

-- Every indent is shown as 4 spaces
vim.opt.tabstop = 2

-- Manual indent by 4 spaces
vim.opt.shiftwidth = 2
