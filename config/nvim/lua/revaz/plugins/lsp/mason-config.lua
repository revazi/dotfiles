-- import mason plugin safely
local mason_status, mason = pcall(require, "mason")
if not mason_status then
	return
end

-- import mason-lspconfig plugin safely
local mason_lspconfig_status, mason_lspconfig = pcall(require, "mason-lspconfig")
if not mason_lspconfig_status then
	return
end

-- import mason-null-ls plugin safely
local mason_null_ls_status, mason_null_ls = pcall(require, "mason-null-ls")
if not mason_null_ls_status then
	return
end

-- enable mason
mason.setup()

mason_lspconfig.setup({
	-- list of servers for mason to install
	ensure_installed = {
		"ts_ls", -- ts/js
		"html", -- html
		"cssls", -- css
		"tailwindcss", -- tailwind
		"ansiblels", -- ansible
		"lua_ls", -- lua
		"eslint", -- ts/js
		"biome", -- Patholux formatter/linter
		"emmet_ls", -- css, js, ts, html
		"ruff", -- python
		"dockerls", -- docker
		"yamlls", -- yaml
		"bashls", -- bash
		"marksman", -- markdown
	},
	-- auto-install configured servers (with lspconfig)
	automatic_installation = true, -- not the same as ensure_installed
})

mason_null_ls.setup({
	-- list of formatters & linters for mason to install
	ensure_installed = {
		"prettier", -- ts/js formatter
		"stylua", -- lua formatter
		"ruff",
		"codespell", -- fix common misspellings
		"djlint",
		"editorconfig_checker",
		"dotenv_linter",
		"ansiblelint",
	},
	-- Install only the explicitly listed tools; code-action sources such as
	-- gitsigns are not Mason packages.
	automatic_installation = false,
})
