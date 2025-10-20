return {
	{
		"nvim-telescope/telescope.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		keys = {
			{ "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find files" },
			{ "<leader>fw", "<cmd>Telescope live_grep<cr>", desc = "Live grep" },
			{ "<leader>th", "<cmd>Telescope colorscheme<cr>", desc = "Theme selector" },
		},
		cmd = "Telescope",
		config = function()
			require("telescope").setup({
				pickers = {
					find_files = {
						previewer = false,
					},
					colorscheme = {
						enable_preview = true,
						previewer = false,
						layout_config = {
							height = 0.4,
							width = 0.2,
						},
					},
				},
			})
		end,
	},
}
