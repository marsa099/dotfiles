return {
	"rcarriga/nvim-notify",
	lazy = false,
	priority = 1000,
	config = function()
		local notify = require("notify")

		notify.setup({
			timeout = 3000,
			render = "compact",
			stages = "fade",
			background_colour = "#000000",
		})

		vim.notify = notify
	end,
}
