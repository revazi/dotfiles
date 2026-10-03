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
		local parsers = {
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

		local max_markdown_filesize = 200 * 1024
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
				local filetype = vim.bo[bufnr].filetype

				if filetype == "markdown" or filetype == "pandoc" then
					local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(bufnr))
					if ok and stats and stats.size > max_markdown_filesize then
						vim.treesitter.stop(bufnr)
						return
					end
				end

				if pcall(vim.treesitter.start, bufnr) then
					vim.bo[bufnr].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
				end
			end,
		})
	end,
}
