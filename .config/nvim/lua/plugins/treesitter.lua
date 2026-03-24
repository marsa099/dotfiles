return {
	{
		"nvim-treesitter/nvim-treesitter",
		lazy = false,
		build = ":TSUpdate",
		dependencies = {
			"nvim-treesitter/nvim-treesitter-textobjects",
		},
		config = function()
			require("nvim-treesitter").setup()

			-- Install parsers if missing
			local parsers = { "c_sharp", "lua", "typescript", "javascript", "json", "yaml", "markdown" }
			local installed = require("nvim-treesitter").get_installed()
			local to_install = vim.tbl_filter(function(p)
				return not vim.list_contains(installed, p)
			end, parsers)
			if #to_install > 0 then
				require("nvim-treesitter").install(to_install)
			end
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter-textobjects",
		config = function()
			require("nvim-treesitter-textobjects").setup({
				move = {
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
			})
		end,
	},
}
