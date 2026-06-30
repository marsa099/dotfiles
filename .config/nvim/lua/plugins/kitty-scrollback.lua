return {
	"mikesmithgh/kitty-scrollback.nvim",
	-- Installed so kitty's pager kitten can launch it. The scrollback view itself
	-- runs under a minimal config (~/.config/kitty/ksb-minimal.lua) for a fast start
	-- and a clean, terminal-like UI — all view tuning lives there, not here.
	enabled = true,
	lazy = true,
	cmd = { "KittyScrollbackGenerateKittens", "KittyScrollbackCheckHealth" },
	event = { "User KittyScrollbackLaunch" },
	config = function()
		require("kitty-scrollback").setup()
	end,
}
