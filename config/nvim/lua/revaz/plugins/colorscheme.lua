return {
	{
		"sainnhe/gruvbox-material",
		priority = 1000, -- load early
		lazy = false, -- load on startup
		background = "dark", -- can be "dark", "medium", or "light"
		config = function()
			vim.cmd("colorscheme gruvbox-material")
		end,
	},
}
