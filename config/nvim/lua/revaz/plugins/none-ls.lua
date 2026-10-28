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

		local function has_biome_config(bufnr)
			local name = vim.api.nvim_buf_get_name(bufnr)
			return vim.fs.root(name, { "biome.json", "biome.jsonc" }) ~= nil
		end

		local ruff_fix = {
			name = "ruff_fix",
			method = methods.FORMATTING,
			filetypes = { "python" },
			generator = helpers.formatter_factory({
				command = "ruff",
				args = function(params)
					return {
						"check",
						"--fix",
						"--stdin-filename",
						params.bufname,
						"-",
					}
				end,
				to_stdin = true,
			}),
		}

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
			debug = true,
			log_level = "debug",
			sources = {
				ruff_fix,
				ruff_fmt,
				null_ls.builtins.formatting.prettier,
				null_ls.builtins.formatting.stylua,
				null_ls.builtins.diagnostics.djlint,
				null_ls.builtins.diagnostics.editorconfig_checker,
				null_ls.builtins.diagnostics.dotenv_linter,
				null_ls.builtins.diagnostics.ansiblelint,
				null_ls.builtins.code_actions.gitsigns,
			},
			on_attach = function(client, bufnr)
				vim.notify(("null-ls attached: %s"):format(client.name))

				if client:supports_method("textDocument/formatting") and not has_biome_config(bufnr) then
					local group = vim.api.nvim_create_augroup("LspFormatting", {})
					vim.api.nvim_clear_autocmds({ group = group, buffer = bufnr })
					vim.api.nvim_create_autocmd("BufWritePre", {
						group = group,
						buffer = bufnr,
						callback = function()
							vim.notify("→ running null-ls format")
							vim.lsp.buf.format({
								filter = function(c)
									return c.name == "null-ls"
								end,
								bufnr = bufnr,
							})
						end,
					})
				end
			end,
		})
	end,
}
