return {
	{
		"rmagatti/auto-session",
		init = function()
			-- Don't save terminal buffers into sessions: a restored terminal can't
			-- resurrect its old process, it just re-runs the command (which for
			-- kitty-scrollback.nvim buffers meant piles of dead "command not found" tabs).
			vim.opt.sessionoptions:remove("terminal")
		end,
		opts = {
			auto_session_suppress_dirs = { "~/", "~/Downloads", "/" },
		},
		lazy = false,
	},
}
