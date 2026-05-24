return {
	"akinsho/bufferline.nvim",
	version = "*",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	event = "VeryLazy",
	config = function()
		local function build_opts()
			local c = require("theme.colors").get_colors()
			return {
				highlights = {
					fill = { bg = c.bg },
					background = { fg = c.fg_muted, bg = c.bg },
					buffer_selected = { fg = c.fg, bg = c.bg, bold = true },
					buffer_visible = { fg = c.fg_muted, bg = c.bg },
					separator = { fg = c.bg, bg = c.bg },
					separator_selected = { fg = c.bg, bg = c.bg },
					separator_visible = { fg = c.bg, bg = c.bg },
				},
				options = {
					mode = "buffers",
					diagnostics = "nvim_lsp",
					custom_filter = function(buf_number)
						if vim.fn.bufname(buf_number) == "" then
							return false
						end
						local buf_type = vim.bo[buf_number].buftype
						if buf_type == "terminal" or buf_type == "quickfix" or buf_type == "help" or buf_type == "nofile" then
							return false
						end
						return true
					end,
					offsets = {
						{
							filetype = "NvimTree",
							text = "File Explorer",
							highlight = "Directory",
							separator = true,
						},
					},
					show_buffer_close_icons = true,
					show_close_icon = false,
					separator_style = "slant",
				},
			}
		end

		require("bufferline").setup(build_opts())

		vim.api.nvim_create_autocmd("ColorScheme", {
			group = vim.api.nvim_create_augroup("BufferlineThemeReload", { clear = true }),
			callback = function()
				require("bufferline").setup(build_opts())
			end,
		})
	end,
	keys = {
		{ "<S-h>", "<cmd>BufferLineCyclePrev<cr>", desc = "Previous buffer" },
		{ "<S-l>", "<cmd>BufferLineCycleNext<cr>", desc = "Next buffer" },
		{ "<leader>bp", "<cmd>BufferLineTogglePin<cr>", desc = "Pin buffer" },
		{ "<leader>bP", "<cmd>BufferLineGroupClose ungrouped<cr>", desc = "Close unpinned buffers" },
	},
}
