return {
	{
		"github/copilot.vim",
		cond = function()
			return require("revaz.preflight").feature_available("copilot")
		end,
	},
}
