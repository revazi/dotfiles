return {
	"nvimtools/none-ls.nvim",
	name = "none-ls",
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	config = function()
		local null_ls = require("null-ls")
		local methods = null_ls.methods
		local helpers = require("null-ls.helpers")
		local formatting = require("revaz.formatting")
		local bigfile = require("revaz.bigfile")

		local ruff_fmt = {
			name = "ruff_fmt",
			method = methods.FORMATTING,
			filetypes = { "python" },
			generator = helpers.formatter_factory({
				command = "ruff",
				args = function(params)
					return {
						"format",
						"--stdin-filename",
						params.bufname,
						"-",
					}
				end,
				to_stdin = true,
			}),
		}

		null_ls.setup({
			should_attach = function(bufnr)
				return not bigfile.is_active(bufnr)
			end,
			sources = {
				ruff_fmt,
				null_ls.builtins.formatting.prettier.with({
					filetypes = formatting.prettier_filetypes,
					prefer_local = "node_modules/.bin",
				}),
				null_ls.builtins.formatting.stylua.with({ filetypes = { "lua" } }),
				null_ls.builtins.diagnostics.djlint,
				null_ls.builtins.diagnostics.editorconfig_checker,
				null_ls.builtins.diagnostics.dotenv_linter,
				null_ls.builtins.diagnostics.ansiblelint,
				null_ls.builtins.code_actions.gitsigns,
			},
			on_attach = function(client, bufnr)
				vim.api.nvim_buf_call(bufnr, function()
					if client:supports_method("textDocument/formatting", bufnr) then
						formatting.attach(bufnr)
					end
				end)
			end,
		})
	end,
}
