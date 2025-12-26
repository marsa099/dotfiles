return {
	"folke/trouble.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	cmd = "Trouble",
	opts = {
		auto_close = true,
		focus = true,
		auto_preview = false,
		indent_guides = true,
		indent_lines = true,
		multiline = false,
		modes = {
			qflist = {
				mode = "qflist",
				groups = {
					{ "filename", format = "{file_icon} {filename} {count}" },
				},
				format = "    {text:ts} {pos}",
			},
		},
	},
	config = function(_, opts)
		require("trouble").setup(opts)
		-- Uncomment to highlight search matches in results
		-- vim.api.nvim_set_hl(0, "Search", { bg = "#3a3a4a", underline = true })
	end,
}
