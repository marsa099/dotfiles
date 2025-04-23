require "nvchad.mappings"

-- add yours here
-- require "custom.mappings"

-- :thelp <topic> öppnar help i ny tab
vim.api.nvim_create_user_command("Thelp", function(opts)
  vim.cmd("tab help " .. opts.args)
end, {
  nargs = 1,
  complete = "help",
})

local map = vim.keymap.set

map({ "n", "t" }, "<A-j>", function()
  require("nvchad.term").toggle { pos = "sp", id = "htoggleTerm2" }
end, { desc = "terminal toggleable horizontal term 2" })

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

map("i", "`", "```", { noremap = true })
-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")
--map("n", "gd", require("omnisharp_extended").lsp_definition, { noremap = true })
map("n", "<leader>D", function()
  require("omnisharp_extended").telescope_lsp_references()
end, { noremap = true })
map("n", "gi", require("omnisharp_extended").telescope_lsp_implementation, { noremap = true })
