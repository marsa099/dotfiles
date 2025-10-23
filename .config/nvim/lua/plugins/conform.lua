return {
	{
		"stevearc/conform.nvim",
		lazy = false,
		opts = {
			formatters_by_ft = {
				lua = { "stylua" },
				cs = { "csharpier" },
			},
			formatters = {
				csharpier = {
					command = "dotnet-csharpier",
					args = { "--write-stdout" },
				},
			},
			format_on_save = function(bufnr)
				-- Respect the disable_autoformat variable (can be set globally or per-project)
				if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
					return nil
				end
				return {
					timeout_ms = 500,
					lsp_fallback = true,
				}
			end,
		},
	},
}
