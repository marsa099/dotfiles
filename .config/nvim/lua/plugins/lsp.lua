return {
	{
		"neovim/nvim-lspconfig",
		lazy = false,
		config = function()
			-- Complete LSP keybindings
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
				callback = function(ev)
					local function map(mode, lhs, rhs, desc)
						vim.keymap.set(mode, lhs, rhs, { buffer = ev.buf, desc = desc })
					end

					-- Navigation
					map("n", "gd", vim.lsp.buf.definition, "Go to definition")
					map("n", "gi", vim.lsp.buf.implementation, "Go to implementation")
					map("n", "gr", vim.lsp.buf.references, "Go to references")
					map("n", "gD", vim.lsp.buf.declaration, "Go to declaration")

					-- Information
					map("n", "K", vim.lsp.buf.hover, "Hover documentation")
					map("i", "<C-k>", vim.lsp.buf.signature_help, "Signature help")

					-- Actions
					map("n", "<leader>rn", vim.lsp.buf.rename, "Rename symbol")
					map("n", "<leader>ca", vim.lsp.buf.code_action, "Code action")
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

			-- Configure omnisharp for C#
			vim.lsp.config("omnisharp", {
				root_markers = { "*.sln", "*.csproj", "omnisharp.json", ".git" },
				cmd = {
					"OmniSharp",
					"--languageserver",
					"--hostPID", tostring(vim.fn.getpid()),
				},
				init_options = {
					AutomaticWorkspaceInit = true,
				},
				settings = {
					FormattingOptions = {
						EnableEditorConfigSupport = true,
						OrganizeImports = true,
					},
					RoslynExtensionsOptions = {
						EnableAnalyzersSupport = true,
						EnableImportCompletion = true,
						EnableDecompilationSupport = true,
						AnalyzeOpenDocumentsOnly = false,
						InlayHintsOptions = {
							EnableForParameters = true,
							ForLiteralParameters = true,
							ForIndexerParameters = true,
						},
					},
					Sdk = {
						IncludePrereleases = true,
					},
				},
			})

			-- Configure ts_ls for TypeScript/JavaScript
			vim.lsp.config("ts_ls", {
				root_markers = { "package.json", "tsconfig.json", "jsconfig.json", ".git" },
			})

			-- Enable LSP servers
			vim.lsp.enable("lua_ls")
			vim.lsp.enable("omnisharp")
			vim.lsp.enable("ts_ls")
		end,
	},
}
