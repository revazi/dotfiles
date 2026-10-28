return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"hrsh7th/cmp-nvim-lsp",
	},
	config = function()
		local cmp_nvim_lsp = require("cmp_nvim_lsp")
		local formatting = require("revaz.formatting")
		local server_inventory = require("revaz.lsp.servers")
		local keymap = vim.keymap

		local on_attach = function(client, bufnr)
			local opts = { noremap = true, silent = true, buffer = bufnr }

			formatting.attach(bufnr)

			-- ts_ls specific bindings
			if client.name == "ts_ls" then
				keymap.set("n", "<leader>rf", vim.lsp.buf.rename, opts)
				keymap.set("n", "<leader>oi", function()
					vim.lsp.buf.code_action({
						context = { only = { "source.organizeImports.ts" } },
						diagnostics = vim.diagnostic.get(bufnr),
					})
				end, opts)

				keymap.set("n", "<leader>ru", function()
					vim.lsp.buf.code_action({
						context = { only = { "source.removeUnused.ts" } },
						diagnostics = vim.diagnostic.get(bufnr),
					})
				end, opts)
			end
		end

		local capabilities = cmp_nvim_lsp.default_capabilities()

		vim.api.nvim_create_user_command("LspInfo", function()
			local clients = vim.lsp.get_clients({ bufnr = 0 })
			if #clients == 0 then
				vim.notify("No LSP clients attached to current buffer", vim.log.levels.INFO)
				return
			end

			vim.print(vim.tbl_map(function(client)
				return client.name
			end, clients))
		end, {})

		vim.diagnostic.config({
			virtual_text = false,
			underline = true,
			update_in_insert = false,
			severity_sort = true,
			signs = {
				text = {
					Error = " ",
					Warn = " ",
					Hint = "ﴞ ",
					Info = " ",
				},
			},
		})

		for name, server in pairs(server_inventory.servers) do
			local config = vim.deepcopy(server)
			config.mason = nil
			config.system_dependencies = nil
			config.capabilities = capabilities
			config.on_attach = on_attach
			vim.lsp.config(name, config)
		end

		-- Native Neovim LSP configuration is the only server activation path.
		vim.lsp.enable(server_inventory.names())
	end,
}
