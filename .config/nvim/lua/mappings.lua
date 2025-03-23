require "nvchad.mappings"

-- add yours here
-- require "custom.mappings"

-- :thelp <topic> öppnar help i ny tab
vim.api.nvim_create_user_command("Thelp", function(opts)
  vim.cmd("tab help " .. opts.args)
end, {
    nargs = 1,
    complete = "help"
  })

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")
