return {
	"nvim-tree/nvim-tree.lua",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	cmd = { "NvimTreeToggle", "NvimTreeFindFile" },
	init = function()
		-- recommended settings from nvim-tree docs
		vim.g.loaded_netrw = 1
		vim.g.loaded_netrwPlugin = 1

		-- set arrow color early
		vim.cmd([[ highlight NvimTreeIndentMarker guifg=#3FC5FF ]])
	end,
	config = function()
		require("nvim-tree").setup({
			renderer = {
				icons = {
					glyphs = {
						folder = {
							arrow_closed = "⃗", -- arrow when folder is closed
							arrow_open = "⃕", -- arrow when folder is open
						},
					},
				},
			},
			actions = {
				open_file = {
					window_picker = {
						enable = false,
					},
				},
			},
			-- uncomment if you want to see all git files
			-- git = { ignore = false },
		})
	end,
}
