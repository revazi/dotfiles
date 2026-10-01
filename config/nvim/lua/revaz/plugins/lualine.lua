-- import lualine plugin safely
return {
	"nvim-lualine/lualine.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	event = "VeryLazy",
	config = function()
		-- optionally use a theme like 'nightfly' and override colors
		local ok, nightfly = pcall(require, "lualine.themes.nightfly")
		if ok then
			nightfly.normal.a.bg = "#65D1FF"
			nightfly.insert.a.bg = "#3EFFDC"
			nightfly.visual.a.bg = "#FF61EF"
			nightfly.command = {
				a = {
					gui = "bold",
					bg = "#FFDA7B",
					fg = "#000000",
				},
			}
		end

		require("lualine").setup({
			options = {
				theme = "gruvbox-material", -- or "nightfly" if you want your theme override to apply
			},
		})
	end,
}
