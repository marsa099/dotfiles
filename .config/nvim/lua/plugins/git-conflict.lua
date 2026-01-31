return {
	"akinsho/git-conflict.nvim",
	version = "*",
	event = "BufReadPre",
	opts = {
		default_mappings = false,
		disable_diagnostics = false,
		default_commands = true,
	},
	keys = {
		{ "<leader>co", "<Plug>(git-conflict-ours)", desc = "Choose ours" },
		{ "<leader>ct", "<Plug>(git-conflict-theirs)", desc = "Choose theirs" },
		{ "<leader>cb", "<Plug>(git-conflict-both)", desc = "Choose both" },
		{ "<leader>c0", "<Plug>(git-conflict-none)", desc = "Choose none" },
		{ "]x", "<Plug>(git-conflict-next-conflict)", desc = "Next conflict" },
		{ "[x", "<Plug>(git-conflict-prev-conflict)", desc = "Previous conflict" },
	},
}
