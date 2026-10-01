return {
	"nvim-treesitter/nvim-treesitter",
	build = ":TSUpdate",
	event = { "BufReadPost", "BufNewFile" },
	dependencies = {
		{ "windwp/nvim-ts-autotag" },
	},
	config = function()
		local max_markdown_filesize = 200 * 1024

		local function is_large_markdown(lang, buf)
			if lang ~= "markdown" and lang ~= "markdown_inline" then
				return false
			end

			local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
			return ok and stats and stats.size > max_markdown_filesize
		end

		require("nvim-treesitter.configs").setup({
			highlight = {
				enable = true,
				disable = is_large_markdown,
			},
			indent = {
				enable = true,
				disable = is_large_markdown,
			},
			autotag = {
				enable = true,
			},
			ensure_installed = {
				"json",
				"javascript",
				"typescript",
				"tsx",
				"yaml",
				"html",
				"css",
				"markdown",
				"svelte",
				"graphql",
				"bash",
				"lua",
				"vim",
				"dockerfile",
				"gitignore",
				"python",
				"rust",
			},
			auto_install = true,
		})
	end,
}
