local M = {}

local javascript_filetypes = {
	"javascript",
	"javascriptreact",
	"typescript",
	"typescriptreact",
}

local function configured_root(markers)
	return function(bufnr, on_dir)
		local root = vim.fs.root(bufnr, markers)
		if root then
			on_dir(root)
		end
	end
end

M.servers = {
	ansiblels = {
		mason = true,
		cmd = { "ansible-language-server", "--stdio" },
		filetypes = { "yaml.ansible" },
		system_dependencies = { "ansible" },
	},
	bashls = {
		mason = true,
		cmd = { "bash-language-server", "start" },
		filetypes = { "bash", "sh" },
	},
	biome = {
		mason = true,
		cmd = { "biome", "lsp-proxy" },
		filetypes = {
			"css",
			"html",
			"javascript",
			"javascriptreact",
			"json",
			"jsonc",
			"typescript",
			"typescriptreact",
		},
		root_dir = configured_root({ "biome.json", "biome.jsonc" }),
		workspace_required = true,
	},
	cssls = {
		mason = true,
		cmd = { "vscode-css-language-server", "--stdio" },
		filetypes = { "css", "scss", "less" },
	},
	dockerls = {
		mason = true,
		cmd = { "docker-langserver", "--stdio" },
		filetypes = { "dockerfile" },
	},
	emmet_ls = {
		mason = true,
		cmd = { "emmet-ls", "--stdio" },
		filetypes = {
			"css",
			"html",
			"javascriptreact",
			"less",
			"sass",
			"scss",
			"typescriptreact",
		},
	},
	eslint = {
		mason = true,
		cmd = { "vscode-eslint-language-server", "--stdio" },
		filetypes = javascript_filetypes,
		root_dir = configured_root({
			"eslint.config.js",
			"eslint.config.cjs",
			"eslint.config.mjs",
			"eslint.config.ts",
			"eslint.config.cts",
			"eslint.config.mts",
			".eslintrc",
			".eslintrc.js",
			".eslintrc.cjs",
			".eslintrc.json",
			".eslintrc.yaml",
			".eslintrc.yml",
		}),
		settings = {
			workingDirectory = { mode = "auto" },
		},
		workspace_required = true,
	},
	html = {
		mason = true,
		cmd = { "vscode-html-language-server", "--stdio" },
		filetypes = { "html" },
	},
	lua_ls = {
		mason = true,
		cmd = { "lua-language-server" },
		filetypes = { "lua" },
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
	marksman = {
		mason = true,
		cmd = { "marksman", "server" },
		filetypes = { "markdown", "markdown.mdx" },
	},
	pyright = {
		mason = true,
		cmd = { "pyright-langserver", "--stdio" },
		filetypes = { "python" },
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
	ruff = {
		mason = true,
		cmd = { "ruff", "server" },
		filetypes = { "python" },
		settings = {
			logLevel = "Debug",
		},
	},
	tailwindcss = {
		mason = true,
		cmd = { "tailwindcss-language-server", "--stdio" },
		filetypes = {
			"css",
			"html",
			"javascript",
			"javascriptreact",
			"less",
			"sass",
			"scss",
			"typescript",
			"typescriptreact",
		},
		workspace_required = true,
	},
	ts_ls = {
		mason = true,
		cmd = { "typescript-language-server", "--stdio" },
		filetypes = javascript_filetypes,
	},
	yamlls = {
		mason = true,
		cmd = { "yaml-language-server", "--stdio" },
		filetypes = { "yaml", "yaml.docker-compose", "yaml.gitlab", "yaml.helm-values" },
	},
}

function M.names()
	local names = vim.tbl_keys(M.servers)
	table.sort(names)
	return names
end

function M.mason_names()
	return vim.tbl_filter(function(name)
		return M.servers[name].mason
	end, M.names())
end

return M
