return {
	{
		"neovim/nvim-lspconfig",
		lazy = false,
		config = function()
			-- Basic LSP keybindings
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
				callback = function(ev)
					local opts = { buffer = ev.buf }
					vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
					vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
					vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
					vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
				end,
			})

			-- Configure lua_ls for Neovim development using new vim.lsp.config API
			vim.lsp.config("lua_ls", {
				root_markers = { ".luarc.json", ".git" },
				settings = {
					Lua = {
						runtime = {
							version = "LuaJIT",
						},
						diagnostics = {
							globals = { "vim" }, -- Recognize 'vim' global to avoid warnings when using `vim.g.relativenumber = true` for instance
						},
						-- - Enables autocompletion for all Neovim API functions (vim.api.*, vim.fn.*, etc.)
						-- Enables go-to-definition for Neovim functions
						-- Shows function signatures and documentation

						-- Example without this:
						-- vim.api.nvim_buf_set_lines()  -- No completion, no signature help

						-- Example with this:
						-- vim.api.nvim_buf_set_lines(  -- ✓ Shows: (buffer, start, end, strict_indexing, replacement)

						workspace = {
							library = vim.api.nvim_get_runtime_file("", true), -- Neovim runtime files
							checkThirdParty = false, -- Disable workspace check prompt
						},
					},
				},
			})

			-- Enable lua_ls for Lua files
			vim.lsp.enable("lua_ls")
		end,
	},
}
