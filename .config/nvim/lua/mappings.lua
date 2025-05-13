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

map(
  "n",
  "<leader>dp",
  "<cmd>%delete _<bar>0put +<CR>",
  { desc = "Replace buffer with clipboard", noremap = true, silent = true }
)

map("n", "<leader>%y", function()
  -- Hämta filnamn utan path
  local fname = vim.fn.expand "%:t"
  -- Hämta alla rader i buffern
  local buf = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  -- Bygg en lista med fname + tom rad + själva innehållet
  local content = { fname, "" }
  for _, line in ipairs(buf) do
    table.insert(content, line)
  end
  -- Skriv till system-clipboard
  vim.fn.setreg("+", content)
  -- Valfritt meddelande:
  vim.notify("Kopierade: " .. fname, vim.log.levels.INFO)
end, {
  desc = "Insert buffer to clipboard",
  noremap = true,
  silent = true,
})

local function yank_diagnostics()
  -- 1) sätt location-list utan att öppna
  vim.diagnostic.setloclist { open = false }
  -- 2) öppna, yanka hela fönstret till +-registret, stäng
  vim.cmd "lopen"
  vim.cmd "%yank +"
  vim.cmd "lclose"
  -- valfri notis
  vim.notify("Diagnostics yanked to clipboard", vim.log.levels.INFO)
end

map("n", "<leader>cd", yank_diagnostics, { desc = "Yank diagnostics to clipboard", noremap = true, silent = true })

map("n", "<leader>gc", "<cmd>CopilotChatToggle<CR>", {
  noremap = true,
  silent = true,
  desc = "Toggle Copilot Chat",
})

map("n", "<leader>ga", "<cmd>CopilotChatAgents<CR>", {
  noremap = true,
  silent = true,
  desc = "Select Copilot chat agent",
})
