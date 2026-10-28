return {
	"williamboman/mason.nvim",
	lazy = false,
	cmd = "Mason",
	build = vim.env.DOTFILES_NVIM_SMOKE ~= "1" and ":MasonUpdate" or nil,
	dependencies = {
		"williamboman/mason-lspconfig.nvim",
		"jay-babu/mason-null-ls.nvim",
	},
	config = function()
		local server_inventory = require("revaz.lsp.servers")
		local smoke = vim.env.DOTFILES_NVIM_SMOKE == "1"

		require("mason").setup()
		require("mason-lspconfig").setup({
			ensure_installed = smoke and {} or server_inventory.mason_names(),
			-- vim.lsp.enable() in lspconfig.lua is the sole activation path.
			automatic_enable = false,
		})
		require("mason-null-ls").setup({
			ensure_installed = smoke and {} or {
				"ansiblelint",
				"djlint",
				"dotenv_linter",
				"editorconfig_checker",
				"prettier",
				"ruff",
				"stylua",
			},
			automatic_installation = false,
		})
	end,
}
