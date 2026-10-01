return {
	"williamboman/mason.nvim",
	lazy = false,
	dependencies = {
		"williamboman/mason-lspconfig.nvim",
		"jay-babu/mason-null-ls.nvim",
	},
	build = ":MasonUpdate",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		require("revaz.plugins.lsp.mason-config") -- move your mason logic into this file
	end,
}
