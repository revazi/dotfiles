return {
	{ "neovim/nvim-lspconfig", event = { "BufReadPre", "BufNewFile" } },
	{
		"williamboman/mason.nvim",
		cmd = "Mason",
		build = vim.env.DOTFILES_NVIM_SMOKE ~= "1" and ":MasonUpdate" or nil,
	},
	{ "williamboman/mason-lspconfig.nvim" },
	{ "nvimtools/none-ls.nvim", dependencies = { "nvim-lua/plenary.nvim" } },
	{ "jay-babu/mason-null-ls.nvim" },
	{ "glepnir/lspsaga.nvim", branch = "main", event = "LspAttach" },
	{ "onsails/lspkind.nvim" },
}
