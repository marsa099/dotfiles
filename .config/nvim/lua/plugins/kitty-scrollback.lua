return {
	"mikesmithgh/kitty-scrollback.nvim",
	enabled = true,
	lazy = true,
	cmd = { "KittyScrollbackGenerateKittens", "KittyScrollbackCheckHealth" },
	event = { "User KittyScrollbackLaunch" },
	config = function()
		require("kitty-scrollback").setup()
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "kitty-scrollback",
			callback = function()
				vim.wo.number = true
				vim.wo.relativenumber = true
			end,
		})
	end,
}
