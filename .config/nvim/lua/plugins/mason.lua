return {
	{
		"mason-org/mason.nvim",
		opts = {},
		lazy = false,
	},
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		dependencies = { "mason-org/mason.nvim" },
		opts = {
			ensure_installed = {
				"bicep-lsp",
			},
		},
		lazy = false,
	},
}
