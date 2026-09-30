-- ANSI scrollback pager for Herdr. Deliberately independent of the main nvim config.
-- Like ksb-minimal.lua: no editor chrome, relative numbers, clipboard yanks, bottom first.
vim.o.laststatus = 0
vim.o.showtabline = 0
vim.o.cmdheight = 0
vim.o.ruler = false
vim.o.showmode = false
vim.o.termguicolors = true
vim.o.clipboard = "unnamedplus"
vim.o.swapfile = false
vim.o.writebackup = false
vim.o.backup = false
vim.o.shadafile = "NONE"
vim.o.scrollback = 100000
vim.o.mouse = "a"
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.report = 999999
vim.opt.shortmess:append("AI")

-- Match Kitty's palette for indexed ANSI colors as well as RGB sequences.
local colors = {}
local theme = vim.fn.expand("~/.config/kitty/theme.conf")
if vim.fn.filereadable(theme) == 1 then
  for _, line in ipairs(vim.fn.readfile(theme)) do
    local key, value = line:match("^(%S+)%s+(#%x%x%x%x%x%x)%s*$")
    if key then
      colors[key] = value
      local index = key:match("^color(%d+)$")
      if index then vim.g["terminal_color_" .. index] = value end
    end
  end
end
vim.api.nvim_set_hl(0, "Normal", { fg = colors.foreground, bg = "none" })
vim.api.nvim_set_hl(0, "NormalNC", { fg = colors.foreground, bg = "none" })
vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = "none" })
vim.api.nvim_set_hl(0, "LineNr", { fg = "#50565e", bg = "none" })
vim.api.nvim_set_hl(0, "CursorLineNr", { fg = colors.foreground, bg = "none" })
vim.api.nvim_set_hl(0, "Visual", { bg = colors.selection_background or "#282F38" })

local function window_options()
  vim.wo.number = true
  vim.wo.relativenumber = true
  vim.wo.numberwidth = 1
  vim.wo.signcolumn = "no"
  vim.wo.foldcolumn = "0"
  vim.wo.winbar = ""
  vim.wo.cursorline = false
  vim.wo.cursorcolumn = false
  vim.wo.colorcolumn = ""
  vim.wo.scrolloff = 0
  vim.wo.wrap = false
  vim.wo.fillchars = "eob: "
end

vim.keymap.set("n", "q", "<cmd>qa!<cr>", { silent = true })
vim.keymap.set("n", "<Esc>", "<cmd>qa!<cr>", { silent = true })
-- This is a frozen pager, never an interactive terminal.
vim.api.nvim_create_autocmd("TermEnter", { callback = function() vim.cmd.stopinsert() end })
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    local ev = vim.v.event
    if ev.operator ~= "y" then return end
    local lines = {}
    for _, line in ipairs(ev.regcontents) do
      lines[#lines + 1] = line:gsub("^%s+", ""):gsub("%s+$", "")
    end
    while #lines > 1 and lines[#lines] == "" do table.remove(lines) end
    while #lines > 1 and lines[1] == "" do table.remove(lines, 1) end
    vim.fn.setreg(ev.regname ~= "" and ev.regname or '"', lines, ev.regtype)
    -- Characterwise clipboard prevents an unwanted Enter when pasting commands.
    vim.fn.setreg("+", lines, "v")
  end,
})

vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    local path = vim.env.HERDR_SCROLLBACK_FILE
    if not path or vim.fn.filereadable(path) ~= 1 then
      vim.api.nvim_err_writeln("Missing Herdr scrollback capture")
      return
    end
    local buf = vim.api.nvim_get_current_buf()
    local columns = vim.o.columns
    -- Like kitty-scrollback.nvim, decode at a wide width before freezing the terminal.
    -- This avoids wrapping at the number gutter and preserves original hard line breaks.
    local width = columns
    for _, line in ipairs(vim.fn.readfile(path)) do
      -- Byte length overestimates width (ANSI/Unicode), which is safe for this purpose.
      width = math.max(width, #line + 1)
    end
    vim.o.columns = math.min(10000, width)
    vim.wo.number = false
    vim.wo.relativenumber = false
    local opts = {
      on_exit = function(_, code)
        vim.schedule(function()
          vim.o.columns = columns
          if code ~= 0 then
            vim.api.nvim_err_writeln("Could not render Herdr scrollback")
            return
          end
          local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
          local last = #lines
          -- Neovim <= 0.11 appends a process-exit line; 0.12 uses virtual text.
          while last > 1 and (lines[last]:match("^%s*$") or lines[last]:match("^%[Process exited %d+%]$")) do
            last = last - 1
          end
          vim.bo[buf].modifiable = true
          vim.api.nvim_buf_set_lines(buf, last, -1, false, {})
          vim.bo[buf].modifiable = false
          vim.bo[buf].modified = false
          vim.bo[buf].filetype = "herdr-scrollback"
          vim.bo[buf].syntax = ""
          local exit_ns = vim.api.nvim_get_namespaces()["nvim.terminal.exitmsg"]
          if exit_ns then vim.api.nvim_buf_clear_namespace(buf, exit_ns, 0, -1) end
          window_options()
          vim.cmd.stopinsert()
          vim.api.nvim_win_set_cursor(0, { last, 0 })
          vim.cmd("normal! zb")
          vim.g.herdr_scrollback_ready = true
        end)
      end,
    }
    local job
    if vim.fn.has("nvim-0.11") == 1 then
      opts.term = true
      job = vim.fn.jobstart({ "cat", "--", path }, opts)
    else
      job = vim.fn.termopen({ "cat", "--", path }, opts)
    end
    if job <= 0 then vim.api.nvim_err_writeln("Could not start scrollback renderer") end
  end,
})
