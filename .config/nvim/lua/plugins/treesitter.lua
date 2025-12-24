return {
	{
		"nvim-treesitter/nvim-treesitter",
		lazy = false,
		build = ":TSUpdate",
		dependencies = {
			"nvim-treesitter/nvim-treesitter-textobjects",
		},
		config = function()
			require("nvim-treesitter.configs").setup({
				ensure_installed = {
					"c_sharp",
					"lua",
					"typescript",
					"javascript",
					"json",
					"yaml",
					"markdown",
				},
				auto_install = true,
				highlight = {
					enable = true,
					-- Explicitly disable vim regex highlighting (default is false per nvim-treesitter docs)
					-- Set explicitly per Catppuccin FAQ to prevent incorrect colors if default changes
					-- Treesitter docs: https://github.com/nvim-treesitter/nvim-treesitter
					-- Catppuccin FAQ: https://github.com/catppuccin/nvim#why-do-my-treesitter-highlights-look-incorrect
					additional_vim_regex_highlighting = false,
				},
				indent = {
					enable = true,
				},
				textobjects = {
					move = {
						enable = true,
						set_jumps = true,
						goto_next_start = {
							["]m"] = "@function.outer",
						},
						goto_next_end = {
							["]M"] = "@function.outer",
						},
						goto_previous_start = {
							["[m"] = "@function.outer",
						},
						goto_previous_end = {
							["[M"] = "@function.outer",
						},
					},
				},
			})
		end,
	},
}
