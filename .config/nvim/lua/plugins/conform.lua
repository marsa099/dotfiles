return {
	{
		"stevearc/conform.nvim",
		lazy = false,
		opts = {
			formatters_by_ft = {
				lua = { "stylua" },
			},
			format_on_save = function(bufnr)
				-- Respect the disable_autoformat variable (can be set globally or per-project)
				if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
					return nil
				end
				return {
					timeout_ms = 2000,
					lsp_fallback = true,
				}
			end,
		},
	},
}
