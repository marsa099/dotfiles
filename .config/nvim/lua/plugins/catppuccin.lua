return {
	"catppuccin/nvim",
	name = "catppuccin",
	lazy = false,
	priority = 1000,
	config = function()
		require("catppuccin").setup({
			flavour = "frappe",
			integrations = {
				treesitter = true,
				native_lsp = {
					enabled = true,
				},
				blink_cmp = true,
				telescope = true,
				nvim_tree = true,
			},
		})

		vim.cmd.colorscheme("catppuccin")
	end,
}
