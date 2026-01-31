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

			-- OmniSharp progress indicator
			local omnisharp_state = {
				min_remaining = math.huge,
				max_total = 0,
				max_projects = 0,
				notify_id = nil,
				initial_done = false,
			}

			vim.lsp.handlers["o#/backgrounddiagnosticstatus"] = function(_, result)
				local total = result.NumberFilesTotal or 0
				local remaining = result.NumberFilesRemaining or 0
				local projects = result.NumberProjects or 0

				-- Filter: ignore messages with no projects (initialization noise)
				if projects == 0 then return end

				-- After initial analysis, ignore all subsequent notifications
				if omnisharp_state.initial_done then return end

				-- Status 2 = analysis complete
				-- Only show completion if we were actively tracking a multi-file analysis
				-- (notify_id will be set when we showed progress)
				if result.Status == 2 and omnisharp_state.notify_id ~= nil then
					vim.notify("Analysis complete", vim.log.levels.INFO, {
						title = "OmniSharp",
						replace = omnisharp_state.notify_id,
						timeout = 3000,
					})
					-- Mark initial analysis as done - no more notifications after this
					omnisharp_state.initial_done = true
					return
				end

				-- Status 1 = actively analyzing
				if result.Status == 1 and total > 0 then
					-- Only track multi-file analyses (initial load), ignore single-file re-analysis
					if total < 2 then return end

					-- Track maximums (totals can increase as projects are discovered)
					if total > omnisharp_state.max_total then
						omnisharp_state.max_total = total
					end
					if projects > omnisharp_state.max_projects then
						omnisharp_state.max_projects = projects
					end

					-- Only update if progress increased (remaining decreased)
					if remaining < omnisharp_state.min_remaining then
						omnisharp_state.min_remaining = remaining

						local done = omnisharp_state.max_total - omnisharp_state.min_remaining
						local pct = math.floor((done / omnisharp_state.max_total) * 100)

						omnisharp_state.notify_id = vim.notify(
							string.format("%d%% (%d/%d files, %d projects)",
								pct, done, omnisharp_state.max_total, omnisharp_state.max_projects),
							vim.log.levels.INFO,
							{ title = "OmniSharp", replace = omnisharp_state.notify_id, timeout = false }
						)
					end
				end
			end

			-- Suppress OmniSharp notifications that flood nvim (from lsp.log analysis):
			-- 25710x o#/projectdiagnosticstatus
			-- 6442x  o#/msbuildprojectdiagnostics
			-- 6338x  o#/projectconfiguration
			-- 2244x  o#/projectchanged
			-- 1722x  o#/projectadded
			-- 60x    o#/error
			-- 42x    o#/unresolveddependencies
			-- Note: o#/backgrounddiagnosticstatus (25718x) is handled above for progress indicator
			vim.lsp.handlers["o#/projectdiagnosticstatus"] = function() end
			vim.lsp.handlers["o#/msbuildprojectdiagnostics"] = function() end
			vim.lsp.handlers["o#/projectconfiguration"] = function() end
			vim.lsp.handlers["o#/projectchanged"] = function() end
			vim.lsp.handlers["o#/projectadded"] = function() end
			vim.lsp.handlers["o#/error"] = function() end
			vim.lsp.handlers["o#/unresolveddependencies"] = function() end

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

			-- Configure omnisharp for C# using vim.lsp.config API
			-- Key: use solution-level root (omnisharp.json or .sln) to avoid spawning
			-- multiple OmniSharp instances per project
			vim.lsp.config("omnisharp", {
				cmd = { "OmniSharp", "--languageserver", "--hostPID", tostring(vim.fn.getpid()) },
				-- Root at solution level, not per-project
				root_markers = { "omnisharp.json", "*.sln" },
				-- NOTE: OmniSharp reads settings from omnisharp.json, not this table.
				-- These serve as defaults/documentation for projects without omnisharp.json.
				settings = {
					FormattingOptions = {
						EnableEditorConfigSupport = true,
						OrganizeImports = true,
					},
					RoslynExtensionsOptions = {
						EnableAnalyzersSupport = false,
						EnableImportCompletion = true,
						EnableDecompilationSupport = true,
						AnalyzeOpenDocumentsOnly = true,
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

			-- Refresh semantic tokens when nvim regains focus (fixes highlighting after branch switches)
			vim.api.nvim_create_autocmd("FocusGained", {
				pattern = "*.cs",
				callback = function()
					vim.cmd("checktime")
					local bufnr = vim.api.nvim_get_current_buf()
					local ok, err = pcall(vim.lsp.semantic_tokens.force_refresh, bufnr)
					if not ok then
						vim.notify("Semantic token refresh failed: " .. tostring(err), vim.log.levels.ERROR)
					end
				end,
			})

			-- Configure ts_ls for TypeScript/JavaScript
			vim.lsp.config("ts_ls", {
				root_markers = { "package.json", "tsconfig.json", "jsconfig.json", ".git" },
			})

			-- Enable LSP servers
			vim.lsp.enable("lua_ls")
			vim.lsp.enable("ts_ls")
			vim.lsp.enable("omnisharp")
		end,
	},
}
