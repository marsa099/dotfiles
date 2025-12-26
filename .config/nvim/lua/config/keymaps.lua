-- Keybindings

-- Window navigation
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Move to window below" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Move to window above" })

-- Buffer management
vim.keymap.set("n", "<leader>x", ":bd<CR>", { desc = "Close current buffer" })

-- Quickfix toggle (using Trouble for better UI)
vim.keymap.set("n", "<C-q>", "<cmd>Trouble qflist toggle<cr>", { desc = "Toggle quickfix (Trouble)" })
