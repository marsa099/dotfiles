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

			-- Suppress OmniSharp-specific notifications that nvim doesn't understand
			local omnisharp_notifications = {
				"o#/projectdiagnosticstatus",
				"o#/projectconfiguration",
				"o#/unresolveddependencies",
				"o#/msbuildprojectdiagnostics",
				"o#/packagerestorestarted",
				"o#/packagerestorefinished",
				"o#/projectadded",
				"o#/projectchanged",
				"o#/projectremoved",
				"o#/error",
				"o#/testmessage",
				"o#/dotnettest/message",
			}
			for _, method in ipairs(omnisharp_notifications) do
				vim.lsp.handlers[method] = function() end
			end

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

			-- Configure omnisharp for C#
			-- Custom startup with Mono vs .NET Core detection and proper client reuse
			local omnisharp_ready_notified = {}  -- Track "ready" notifications per root
			vim.api.nvim_create_autocmd("FileType", {
				pattern = { "cs" },
				callback = function(args)
					local root = vim.fs.root(args.buf, function(name, path)
						return name == "omnisharp.json" or name:match("%.sln$")
					end)
					if not root then return end

					-- Check if OmniSharp is already running for this root
					local client_exists = false
					local existing_clients = vim.lsp.get_clients({ name = "omnisharp" })
					for _, client in ipairs(existing_clients) do
						if client.root_dir == root then
							client_exists = true
							break
						end
					end

					local cmd, build_type
					local use_mono = false
					if vim.fn.filereadable(root .. "/omnisharp.json") == 1 then
						local ok, content = pcall(vim.fn.readfile, root .. "/omnisharp.json")
						if ok then
							local json_ok, json = pcall(vim.fn.json_decode, table.concat(content, "\n"))
							use_mono = json_ok and json and json.mono == true
						end
					end
					if use_mono then
						-- .NET Framework project - use Mono build (runs via: mono OmniSharp.exe)
						cmd = { "/opt/omnisharp-mono/run", "--languageserver" }
						build_type = "Mono (net472)"
					else
						-- .NET Core/5+ project - use Mason build (runs via: dotnet OmniSharp.dll)
						cmd = { "OmniSharp", "--languageserver", "--hostPID", tostring(vim.fn.getpid()) }
						build_type = ".NET Core (net6.0)"
					end

					-- Only show "starting" notification for new clients
					if not client_exists then
						vim.notify("OmniSharp: " .. build_type .. " (starting...)", vim.log.levels.INFO)
					end

					-- vim.lsp.start() reuses existing client if name + root_dir match
					vim.lsp.start({
						name = "omnisharp",
						cmd = cmd,
						root_dir = root,
						on_attach = function()
							if not omnisharp_ready_notified[root] then
								omnisharp_ready_notified[root] = true
								vim.notify("OmniSharp: " .. build_type .. " (ready)", vim.log.levels.INFO)
							end
						end,
						settings = {
							FormattingOptions = {
								EnableEditorConfigSupport = true,
								OrganizeImports = true,
							},
							RoslynExtensionsOptions = {
								EnableAnalyzersSupport = true,
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
				end,
			})

			-- Configure ts_ls for TypeScript/JavaScript
			vim.lsp.config("ts_ls", {
				root_markers = { "package.json", "tsconfig.json", "jsconfig.json", ".git" },
			})

			-- Enable LSP servers
			vim.lsp.enable("lua_ls")
			vim.lsp.enable("ts_ls")
		end,
	},
}
