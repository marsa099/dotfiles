require "nvchad.mappings"

-- add yours here
-- require "custom.mappings"

-- :thelp <topic> opens help in new tab
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
-- OmniSharp extended keybindings moved to omnisharp-extended.lua plugin config

map(
  "n",
  "<leader>dp",
  "<cmd>%delete _<bar>0put +<CR>",
  { desc = "Replace buffer with clipboard", noremap = true, silent = true }
)

map("n", "<leader>%y", function()
  -- Get filename without path
  local fname = vim.fn.expand "%:t"
  -- Get all lines in buffer
  local buf = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  -- Build list with filename + empty line + content
  local content = { fname, "" }
  for _, line in ipairs(buf) do
    table.insert(content, line)
  end
  -- Write to system clipboard
  vim.fn.setreg("+", content)
  -- Optional notification
  vim.notify("Copied: " .. fname, vim.log.levels.INFO)
end, {
  desc = "Insert buffer to clipboard",
  noremap = true,
  silent = true,
})

local function yank_diagnostics()
  -- 1) set location-list without opening
  vim.diagnostic.setloclist { open = false }
  -- 2) open, yank entire window to + register, close
  vim.cmd "lopen"
  vim.cmd "%yank +"
  vim.cmd "lclose"
  -- optional notification
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

map("n", "<leader>po", "o<Esc>p", {
  noremap = true,
  silent = true,
  desc = "Open line below, return to normal and paste",
})
