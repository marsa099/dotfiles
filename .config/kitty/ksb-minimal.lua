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

-- plain `y` copies straight to the system (Wayland) clipboard, no staging window.
-- A plain yank has regname '' so it won't trigger the plugin's '+'-register auto-close;
-- it just copies and leaves the scrollback open.
vim.o.clipboard = "unnamedplus"

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
		paste_window = {
			-- We use this as a read-only pager, not a send-to-shell tool. Without this,
			-- a plain `y` drops the yanked text into a floating "paste" staging window
			-- (yank_register defaults to the unnamed register). Disable that.
			yank_register_enabled = false,
		},
		callbacks = {
			-- The plugin hardcodes --add-wrap-markers on `kitty @ get-text` so blank
			-- screen rows become real buffer lines, padding the buffer to full terminal
			-- height (its cursor math needs that). We don't want the padding: once the
			-- plugin is done positioning, strip the trailing blank lines and park the
			-- cursor on the last content line (= the prompt row), like the terminal.
			-- Content shorter than the window then renders from the top, exactly as it
			-- did in the terminal.
			after_ready = function(kitty_data)
				local buf = vim.api.nvim_get_current_buf()
				local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
				local last = #lines
				while last > 1 and lines[last]:match("^%s*$") do
					last = last - 1
				end
				if last < #lines then
					-- finished terminal buffer: modifiable can be toggled to edit it
					vim.bo[buf].modifiable = true
					vim.api.nvim_buf_set_lines(buf, last, -1, false, {})
					vim.bo[buf].modifiable = false
				end
				-- if kitty was scrolled up when opened, the plugin preserved that view;
				-- moving the cursor to the last line would yank it back down — skip.
				if (kitty_data.scrolled_by or 0) <= 0 then
					vim.api.nvim_win_set_cursor(0, { last, 0 })
				end
			end,
		},
	},
})

-- Strip trailing whitespace from each yanked line before it reaches the clipboard.
-- Kitty pads every captured row out to the full terminal width with spaces, so a
-- block selection drags along a lot of trailing padding. Leading whitespace is left
-- intact (it's real indentation for copied code).
vim.api.nvim_create_autocmd("TextYankPost", {
	group = vim.api.nvim_create_augroup("KsbTrimTrailingOnYank", { clear = true }),
	callback = function()
		local ev = vim.v.event
		if ev.operator ~= "y" then
			return
		end
		local trimmed, changed = {}, false
		for _, line in ipairs(ev.regcontents) do
			local t = line:gsub("%s+$", "")
			changed = changed or t ~= line
			trimmed[#trimmed + 1] = t
		end
		if not changed then
			return
		end
		local regname = ev.regname ~= "" and ev.regname or '"'
		vim.fn.setreg(regname, trimmed, ev.regtype) -- setreg does not re-fire TextYankPost
		vim.fn.setreg("+", trimmed, ev.regtype) -- mirror to the system clipboard
	end,
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
			-- trailing blank padding is stripped in after_ready, so the region below
			-- the content is end-of-buffer; hide the '~' markers to look like the terminal
			vim.wo[win].fillchars = "eob: "
		end
		apply()
		-- the plugin forces its own window options after the filetype is set, so
		-- re-apply once more on the next tick to win the race
		vim.schedule(apply)
	end,
})
