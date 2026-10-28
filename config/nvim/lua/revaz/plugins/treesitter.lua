return {
	"nvim-treesitter/nvim-treesitter",
	lazy = false,
	build = ":TSUpdate",
	dependencies = {
		{
			"windwp/nvim-ts-autotag",
			opts = {},
		},
	},
	config = function()
		local treesitter = require("nvim-treesitter")
		local install_dir = vim.fn.stdpath("data") .. "/site"
		vim.opt.rtp:prepend(install_dir)

		local parsers = vim.env.DOTFILES_NVIM_SMOKE == "1" and { "markdown", "markdown_inline" }
			or {
				"bash",
				"css",
				"dockerfile",
				"gitignore",
				"graphql",
				"html",
				"javascript",
				"json",
				"lua",
				"markdown",
				"markdown_inline",
				"python",
				"rust",
				"svelte",
				"tsx",
				"typescript",
				"vim",
				"yaml",
			}

		treesitter.install(parsers)

		local bigfile = require("revaz.bigfile")
		local group = vim.api.nvim_create_augroup("TreesitterConfig", { clear = true })

		vim.api.nvim_create_autocmd("FileType", {
			group = group,
			pattern = {
				"bash",
				"css",
				"dockerfile",
				"gitignore",
				"graphql",
				"html",
				"javascript",
				"javascriptreact",
				"json",
				"jsonc",
				"lua",
				"markdown",
				"pandoc",
				"python",
				"rust",
				"sh",
				"svelte",
				"typescript",
				"typescriptreact",
				"typescript.tsx",
				"vim",
				"yaml",
			},
			callback = function(args)
				local bufnr = args.buf
				if bigfile.is_active(bufnr) then
					return
				end

				if pcall(vim.treesitter.start, bufnr) then
					local treesitter_indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
					if vim.bo[bufnr].indentexpr ~= treesitter_indentexpr then
						vim.b[bufnr]._bigfile_saved_indentexpr = vim.bo[bufnr].indentexpr
					end
					vim.bo[bufnr].indentexpr = treesitter_indentexpr
				end
			end,
		})
	end,
}
