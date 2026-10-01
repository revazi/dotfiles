return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"hrsh7th/cmp-nvim-lsp",
		"nvimtools/none-ls.nvim",
	},
	config = function()
		local cmp_nvim_lsp = require("cmp_nvim_lsp")

		local keymap = vim.keymap

		local on_attach = function(client, bufnr)
			local opts = { noremap = true, silent = true, buffer = bufnr }

			-- Patholux uses Biome for formatting, linting, and import organization.
			if client.name == "biome" then
				vim.api.nvim_create_autocmd("BufWritePre", {
					group = vim.api.nvim_create_augroup("BiomeFormat", { clear = false }),
					buffer = bufnr,
					callback = function()
						vim.lsp.buf.code_action({
							context = { only = { "source.fixAll.biome", "source.organizeImports.biome" } },
							apply = true,
							bufnr = bufnr,
						})
						vim.lsp.buf.format({
							filter = function(c)
								return c.name == "biome"
							end,
							bufnr = bufnr,
						})
					end,
				})
			end

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

		-- Diagnostic signs
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

		-- Helpers (Neovim-native root detection)
		local function root_pattern(...)
			local markers = { ... }
			return function(bufname)
				-- bufname can be nil sometimes; fall back to current buffer name
				local name = bufname or vim.api.nvim_buf_get_name(0)
				return vim.fs.root(name, markers)
			end
		end

		local servers = {
			html = {},
			cssls = {},
			tailwindcss = {},
			dockerls = {},
			yamlls = {},
			bashls = {},
			marksman = {},

			pyright = {
				settings = {
					pyright = {
						disableOrganizeImports = true,
					},
					python = {
						analysis = {
							ignore = { "*" },
						},
					},
				},
			},

			eslint = {
				root_dir = root_pattern(
					".eslintrc.js",
					".eslintrc.cjs",
					".eslintrc.json",
					".eslintrc.yaml",
					".eslintrc.yml"
				),
				settings = {
					workingDirectory = { mode = "auto" },
				},
			},

			biome = {
				cmd = { "bunx", "biome", "lsp-proxy" },
				root_markers = { "biome.json", "biome.jsonc" },
			},

			-- Ruff
			ruff = {
				settings = {
					logLevel = "Debug",
				},
			},

			lua_ls = {
				settings = {
					Lua = {
						diagnostics = { globals = { "vim" } },
						workspace = {
							library = {
								[vim.fn.expand("$VIMRUNTIME/lua")] = true,
								[vim.fn.stdpath("config") .. "/lua"] = true,
							},
						},
					},
				},
			},

			emmet_ls = {
				filetypes = {
					"html",
					"typescriptreact",
					"javascriptreact",
					"css",
					"sass",
					"scss",
					"less",
					"svelte",
				},
			},

			-- TypeScript (typescript-language-server)
			ts_ls = {
				cmd = { "typescript-language-server", "--stdio" },
				filetypes = { "typescript", "typescriptreact", "typescript.tsx" },
				root_markers = { "tsconfig.json", "package.json", ".git" },
			},
		}

		for name, cfg in pairs(servers) do
			cfg.capabilities = capabilities
			cfg.on_attach = on_attach

			-- New API (Neovim 0.11+ + nvim-lspconfig new style)
			vim.lsp.config(name, cfg)
			vim.lsp.enable(name)
		end
	end,
}
