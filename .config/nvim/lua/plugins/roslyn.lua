return {
	"seblyng/roslyn.nvim",
	ft = "cs",
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
