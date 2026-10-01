return {
	{ "neovim/nvim-lspconfig", event = { "BufReadPre", "BufNewFile" } },
	{ "williamboman/mason.nvim", cmd = "Mason", build = ":MasonUpdate" },
	{ "williamboman/mason-lspconfig.nvim" },
	{ "nvimtools/none-ls.nvim", dependencies = { "nvim-lua/plenary.nvim" } },
	{ "jay-babu/mason-null-ls.nvim" },
	{ "glepnir/lspsaga.nvim", branch = "main", event = "LspAttach" },
	{ "jose-elias-alvarez/typescript.nvim" },
	{ "onsails/lspkind.nvim" },
}
