return {
	"seblyng/roslyn.nvim",
	-- Not lazy-loaded by ft to avoid race condition:
	-- plugin/roslyn.lua calls vim.lsp.enable before setup(opts) runs,
	-- causing "Multiple potential target files found" on first open.
	-- The LSP server itself only starts when a .cs file is opened.
	lazy = false,
	opts = {
		broad_search = true,
		lock_target = true,
		-- Prefer Linux.sln over Windows-only .sln (new.sis.se has both)
		choose_target = function(targets)
			for _, target in ipairs(targets) do
				if target:match("Linux%.sln$") then
					return target
				end
			end
			return targets[1]
		end,
	},
}
