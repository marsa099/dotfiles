local M = {}

function M.toggle_checkbox()
  local line = vim.api.nvim_get_current_line()
  if line:find('%[ %]') then
    line = line:gsub('%[ %]', '[x]', 1)
  elseif line:find('%[[xX]%]') then
    line = line:gsub('%[[xX]%]', '[ ]', 1)
  else
    return
  end
  vim.api.nvim_set_current_line(line)
end

function M.setup_buffer()
  local opts = { buffer = true, silent = true, nowait = true }
  vim.keymap.set('n', 'q', '<Cmd>qa<CR>', opts)
  vim.keymap.set('n', '<Space>', M.toggle_checkbox, opts)
end

return M
