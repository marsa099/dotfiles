return {
	{
		"mason-org/mason.nvim",
		opts = {
			registries = {
				"github:Crashdummyy/mason-registry",
				"github:mason-org/mason-registry",
			},
		},
		lazy = false,
	},
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		dependencies = { "mason-org/mason.nvim" },
		opts = {
			ensure_installed = {
				"lua-language-server",
				"stylua",
				"roslyn",
				"csharpier",
				"typescript-language-server",
			},
		},
		lazy = false,
	},
}
