-- ~/.config/nvim/lua/revaz/plugins/none-ls.lua
return {
	"nvimtools/none-ls.nvim",
	name = "none-ls", -- keep this if you're using lazy.nvim
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvimtools/none-ls-extras.nvim",
	},
	config = function()
		local null_ls = require("null-ls")
    local methods = null_ls.methods
    local helpers = require("null-ls.helpers")
    local utils   = require("null-ls.utils")

		local function has_biome_config(bufnr)
			local name = vim.api.nvim_buf_get_name(bufnr)
			return vim.fs.root(name, { "biome.json", "biome.jsonc" }) ~= nil
		end

    -- Ruff: first pass (lint fixes)
    local ruff_fix = {
      name      = "ruff_fix",
      method    = methods.FORMATTING,
      filetypes = { "python" },
      generator = helpers.formatter_factory({
        command = "ruff",
        args    = function(params)
          return {
            "check", "--fix",
            "--stdin-filename", params.bufname,
            "-",          -- read from stdin
          }
        end,
        to_stdin = true,
      }),
    }

    -- Ruff: second pass (Black-style formatting)
    local ruff_fmt = {
      name      = "ruff_fmt",
      method    = methods.FORMATTING,
      filetypes = { "python" },
      generator = helpers.formatter_factory({
        command = "ruff",
        args    = function(params)
          return {
            "format",
            "--stdin-filename", params.bufname,
            "-",  -- read from stdin
          }
        end,
        to_stdin = true,
      }),
    }

		-- 1) enable debug logging
		null_ls.setup({
			debug = true,
			log_level = "debug",
			sources = {
				-- extras plugin modules:
				-- require("none-ls.diagnostics.ruff"),
				-- require("none-ls.formatting.ruff"),
        ruff_fix,
        ruff_fmt,

				-- your other formatters/linters:
				null_ls.builtins.formatting.prettier,
				null_ls.builtins.formatting.stylua,
				null_ls.builtins.diagnostics.djlint,
				null_ls.builtins.diagnostics.editorconfig_checker,
				null_ls.builtins.diagnostics.dotenv_linter,
				null_ls.builtins.diagnostics.ansiblelint,
				null_ls.builtins.code_actions.gitsigns,
			},

			on_attach = function(client, bufnr)
				-- 2) debug print to confirm we're in on_attach
				vim.notify(("null-ls attached: %s"):format(client.name))

				if client:supports_method("textDocument/formatting") and not has_biome_config(bufnr) then
					local group = vim.api.nvim_create_augroup("LspFormatting", {})
					vim.api.nvim_clear_autocmds({ group = group, buffer = bufnr })
					vim.api.nvim_create_autocmd("BufWritePre", {
						group = group,
						buffer = bufnr,
						callback = function()
							vim.notify("→ running null-ls format") -- another debug
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
-- return {
-- 	"nvimtools/none-ls.nvim",
-- 	name = "null-ls",
-- 	event = { "BufReadPre", "BufNewFile" },
-- 	dependencies = { "nvim-lua/plenary.nvim", "nvimtools/none-ls-extras.nvim" },
-- 	config = function()
-- 		local null_ls = require("null-ls")
-- 		local formatting = null_ls.builtins.formatting
-- 		local diagnostics = null_ls.builtins.diagnostics
-- 		local code_actions = null_ls.builtins.code_actions
-- 		vim.notify("✅ null-ls plugin loaded!", vim.log.levels.INFO)
--
-- 		-- local function find_project_root(file_names)
-- 		-- 	local lsp_util = require("lspconfig/util")
-- 		-- 	local bufnr = vim.api.nvim_get_current_buf()
-- 		-- 	local bufname = vim.api.nvim_buf_get_name(bufnr)
-- 		-- 	local root = lsp_util.find_git_ancestor(bufname) or lsp_util.path.dirname(bufname)
-- 		--
-- 		-- 	if root then
-- 		-- 		for _, fname in ipairs(file_names) do
-- 		-- 			local full_path = lsp_util.path.join(root, fname)
-- 		-- 			if lsp_util.path.is_file(full_path) then
-- 		-- 				return full_path
-- 		-- 			end
-- 		-- 		end
-- 		-- 	end
-- 		-- 	return nil
-- 		-- end
--
-- 		local sources = {
--
-- 			formatting.prettier.with({
-- 				filetypes = { "javascript", "typescript", "json", "css", "scss", "html", "vue" },
-- 			}),
-- 			-- Lua
-- 			formatting.stylua,
--
-- 			-- Python
-- 			require("none-ls.diagnostics.ruff"),
-- 			require("none-ls.formatting.ruff").with({
-- 				extra_args = { "--fix" },
-- 			}),
-- 			-- Misc
-- 			diagnostics.djlint,
-- 			diagnostics.editorconfig_checker,
-- 			diagnostics.dotenv_linter,
-- 			diagnostics.ansiblelint,
--
-- 			code_actions.gitsigns,
-- 		}
--
-- 		local augroup = vim.api.nvim_create_augroup("LspFormatting", {})
--
-- 		null_ls.setup({
-- 			sources = sources,
-- 			on_attach = function(client, bufnr)
-- 				if client.supports_method("textDocument/formatting") then
-- 					vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
-- 					vim.api.nvim_create_autocmd("BufWritePre", {
-- 						group = augroup,
-- 						buffer = bufnr,
-- 						callback = function()
-- 							vim.lsp.buf.format({
-- 								filter = function(c)
-- 									return c.name == "null-ls"
-- 								end,
-- 								bufnr = bufnr,
-- 							})
-- 						end,
-- 					})
-- 				end
-- 			end,
-- 		})
-- 	end,
-- }
