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
						vim.keymap.set(mode, lhs, rhs, { buf = ev.buf, desc = desc })
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
			-- NixOS workaround: Roslyn 5.6.0's BuildHost (dotnet/roslyn#79494) derives
			-- the dotnet binary path via ../../dotnet relative to the MSBuild location.
			-- On NixOS, MSBuildLocator 1.10.2 replaced libc realpath() with .NET's
			-- File.ResolveLinkTarget() for symlink resolution, which can fail with
			-- NixOS's Nix store symlink chains. We set DOTNET_HOST_PATH and explicit
			-- MSBuild paths so the BuildHost can find the SDK without broken discovery.
			local dotnet_cmd_env = nil
			local dotnet_root = vim.env.DOTNET_ROOT
			if dotnet_root then
				local sdk_dir = vim.fs.joinpath(dotnet_root, "sdk")
				for name, type in vim.fs.dir(sdk_dir) do
					if type == "directory" and name:match("^%d") then
						local sdk_base = vim.fs.joinpath(sdk_dir, name)
						dotnet_cmd_env = {
							DOTNET_ROOT = dotnet_root,
							DOTNET_HOST_PATH = vim.fs.joinpath(dotnet_root, "dotnet"),
							MSBUILD_EXE_PATH = vim.fs.joinpath(sdk_base, "MSBuild.dll"),
							MSBuildSDKsPath = vim.fs.joinpath(sdk_base, "Sdks"),
						}
						break
					end
				end
			end
			vim.lsp.config("roslyn", {
				cmd_env = dotnet_cmd_env,
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

			-- NixOS workaround: When Roslyn starts, files are briefly analyzed in a
			-- "misc" workspace (before the real project loads), causing all usings to
			-- appear unused. After the project finishes loading, we reload .cs buffers
			-- so Roslyn re-analyzes them in the correct project context.
			vim.api.nvim_create_autocmd("User", {
				pattern = "RoslynInitialized",
				group = vim.api.nvim_create_augroup("CSharpReloadAfterProjectInit", { clear = true }),
				callback = function()
					for _, buf in ipairs(vim.api.nvim_list_bufs()) do
						if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype == "cs" then
							vim.api.nvim_buf_call(buf, function()
								vim.cmd.edit()
							end)
						end
					end
				end,
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
			-- Configure nil for Nix
			vim.lsp.config("nil_ls", {
				root_markers = { "flake.nix", ".git" },
			})

			vim.lsp.enable("lua_ls")
			vim.lsp.enable("ts_ls")
			vim.lsp.enable("bicep")
			vim.lsp.enable("nil_ls")
		end,
	},
}
