-- q closes help buffer without need to type : first 
vim.api.nvim_create_autocmd("FileType", {
  pattern = "help",
  callback = function()
    vim.keymap.set("n", "q", "<cmd>quit<CR>", { buffer = true })
  end,
})
