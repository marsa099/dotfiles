return {
	{
		"neovim/nvim-lspconfig",
		lazy = false,
		config = function()
			-- Enable line highlighting for diagnostics
			vim.diagnostic.config({
				signs = {
					linehl = {
						[vim.diagnostic.severity.ERROR] = "DiagnosticLineError",
						[vim.diagnostic.severity.WARN] = "DiagnosticLineWarn",
						[vim.diagnostic.severity.INFO] = "DiagnosticLineInfo",
						[vim.diagnostic.severity.HINT] = "DiagnosticLineHint",
					},
				},
			})

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
					-- gr mapped to Glance references (see glance.lua)
					map("n", "gD", vim.lsp.buf.declaration, "Go to declaration")

					-- Information
					map("n", "K", vim.lsp.buf.hover, "Hover documentation")
					map("i", "<C-k>", vim.lsp.buf.signature_help, "Signature help")
					map("n", "<leader>e", vim.diagnostic.open_float, "Show diagnostic")

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

			-- Configure ts_ls for TypeScript/JavaScript
			vim.lsp.config("ts_ls", {
				root_markers = { "package.json", "tsconfig.json", "jsconfig.json", ".git" },
			})

			-- Configure Roslyn for C# (server lifecycle managed by roslyn.nvim)
			vim.lsp.config("roslyn", {
				settings = {
					["csharp|background_analysis"] = {
						dotnet_analyzer_diagnostics_scope = "openFiles",
						dotnet_compiler_diagnostics_scope = "openFiles",
					},
					["csharp|completion"] = {
						dotnet_show_completion_items_from_unimported_namespaces = true,
						dotnet_show_name_completion_suggestions = true,
					},
					["csharp|formatting"] = {
						dotnet_organize_imports_on_format = true,
					},
				},
			})

			-- Configure Bicep LSP
			vim.lsp.config("bicep", {
				cmd = {
					"dotnet",
					vim.fn.stdpath("data") .. "/mason/packages/bicep-lsp/extension/bicepLanguageServer/Bicep.LangServer.dll",
				},
				root_markers = { ".git" },
			})

			vim.filetype.add({
				extension = {
					bicep = "bicep",
					bicepparam = "bicep",
				},
			})

			-- Remove unused usings on save for C# via Roslyn's proprietary codeAction/resolve
			-- Based on: https://github.com/seblyng/roslyn.nvim/wiki/Tips-and-tricks
			vim.api.nvim_create_autocmd("BufWritePre", {
				pattern = "*.cs",
				group = vim.api.nvim_create_augroup("CSharpRemoveUnusedUsings", { clear = true }),
				callback = function(ev)
					if vim.g.disable_autoformat or vim.b[ev.buf].disable_autoformat then
						return
					end
					local clients = vim.lsp.get_clients({ name = "roslyn", bufnr = ev.buf })
					if vim.tbl_isempty(clients) then
						return
					end
					local action = {
						title = "Remove unnecessary usings",
						kind = "quickfix",
						data = {
							CustomTags = { "RemoveUnnecessaryImports" },
							TextDocument = { uri = vim.uri_from_bufnr(ev.buf) },
							CodeActionPath = { "Remove unnecessary usings" },
							Range = {
								["start"] = { line = 0, character = 0 },
								["end"] = { line = 0, character = 0 },
							},
							UniqueIdentifier = "Remove unnecessary usings",
						},
					}
					local result = vim.lsp.buf_request_sync(ev.buf, "codeAction/resolve", action, 3000)
					if result then
						for _, res in pairs(result) do
							if res.result and res.result.edit then
								vim.lsp.util.apply_workspace_edit(res.result.edit, clients[1].offset_encoding)
							end
						end
					end
				end,
			})

			-- Enable LSP servers
			vim.lsp.enable("lua_ls")
			vim.lsp.enable("ts_ls")
			vim.lsp.enable("bicep")
		end,
	},
}
