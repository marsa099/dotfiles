return {
	{
		"nvim-treesitter/nvim-treesitter",
		lazy = false,
		build = ":TSUpdate",
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
			})
		end,
	},
}
