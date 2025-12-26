return {
	"kevinhwang91/nvim-bqf",
	ft = "qf",
	opts = {
		auto_enable = true,
		auto_resize_height = true,
		preview = {
			auto_preview = false,
			win_height = 15,
			winblend = 0,
			border = "rounded",
			show_title = true,
			delay_syntax = 50,
			should_preview_cb = function(bufnr)
				-- Don't preview files larger than 100KB
				local ret = true
				local filename = vim.api.nvim_buf_get_name(bufnr)
				local fsize = vim.fn.getfsize(filename)
				if fsize > 100 * 1024 then
					ret = false
				end
				return ret
			end,
		},
		filter = {
			fzf = {
				extra_opts = { "--bind", "ctrl-o:toggle-all" },
			},
		},
	},
}
