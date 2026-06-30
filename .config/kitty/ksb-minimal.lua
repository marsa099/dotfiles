-- Minimal Neovim config for the kitty scrollback pager (Ctrl+Shift+H).
-- Loaded via `nvim -u` from kitty.conf so the view starts instantly and carries
-- no tab bar / statusline / winbar / LSP — nothing but kitty-scrollback itself.
-- The plugin is installed by the main nvim config's lazy spec; we just reuse it.

vim.opt.runtimepath:prepend(vim.fn.expand("~/.local/share/nvim/lazy/kitty-scrollback.nvim"))

-- look like the plain terminal: no statusline, no tab bar, no command row
vim.o.laststatus = 0
vim.o.showtabline = 0
vim.o.cmdheight = 0
vim.o.ruler = false

-- transparent background so kitty's background image shows through, like the terminal
local function transparent()
	vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
	vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
	vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = "none" })
end
vim.api.nvim_create_autocmd("ColorScheme", { callback = transparent })
transparent()

require("kitty-scrollback").setup({
	-- global config (first unkeyed entry): applies to every scrollback invocation.
	-- Disable the status window (the cat/heart/nvim loading overlay) — it spawns an
	-- extra kitty window + python spinner loop, adding latency and visual clutter.
	{
		status_window = {
			enabled = false,
		},
	},
})

vim.api.nvim_create_autocmd("FileType", {
	pattern = "kitty-scrollback",
	callback = function(ev)
		-- The plugin forces number/relativenumber=false and scrolloff=2 on its own
		-- window AFTER setting the filetype, so apply our options deferred (and
		-- target the scrollback window explicitly) to win the race.
		local function apply()
			local win = vim.fn.bufwinid(ev.buf)
			if win == -1 then
				win = vim.api.nvim_get_current_win()
			end
			-- line numbers: the ONLY intended difference from the plain terminal
			vim.wo[win].number = true
			vim.wo[win].relativenumber = true
			vim.wo[win].numberwidth = 1
			-- strip every other gutter/decoration
			vim.wo[win].signcolumn = "no"
			vim.wo[win].foldcolumn = "0"
			vim.wo[win].winbar = ""
			vim.wo[win].cursorline = false
			vim.wo[win].cursorcolumn = false
			vim.wo[win].colorcolumn = ""
			-- don't shove the view up when the cursor sits on the last line
			vim.wo[win].scrolloff = 0
		end
		apply()
		vim.schedule(apply)
	end,
})
