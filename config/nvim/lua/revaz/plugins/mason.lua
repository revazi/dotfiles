return {
	"williamboman/mason.nvim",
	lazy = false,
	dependencies = {
		"williamboman/mason-lspconfig.nvim",
		"jay-babu/mason-null-ls.nvim",
	},
	build = vim.env.DOTFILES_NVIM_SMOKE ~= "1" and ":MasonUpdate" or nil,
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		require("revaz.plugins.lsp.mason-config") -- move your mason logic into this file
	end,
}
