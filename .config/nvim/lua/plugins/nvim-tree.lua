return {
	"nvim-tree/nvim-tree.lua",
	keys = {
		{ "<C-n>", "<cmd>NvimTreeToggle<cr>", desc = "Toggle file explorer" },
	},
	-- Lazy-load plugin when these commands are run (improves startup time)
	cmd = { "NvimTreeToggle", "NvimTreeFocus", "NvimTreeFindFile" },
	dependencies = {
		"nvim-tree/nvim-web-devicons",
	},
	config = function()
		require("nvim-tree").setup({
			update_focused_file = {
				enable = true,
				update_root = false,
			},
			renderer = {
				icons = {
					show = {
						file = true,
						folder = true,
						folder_arrow = true,
						git = true,
					},
				},
			},
		})
	end,
}
