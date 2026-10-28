return {
	"lewis6991/gitsigns.nvim",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local gitsigns = require("gitsigns")
		local bigfile = require("revaz.bigfile")
		gitsigns.setup({
			auto_attach = false,
			on_attach = function(bufnr)
				-- This final plugin-native veto also covers an attach that was
				-- already awaiting asynchronous Git work when mode became active.
				return not bigfile.is_active(bufnr)
			end,
		})

		local attach_disabled = false
		local function attach(bufnr, trigger)
			if not attach_disabled and vim.api.nvim_buf_get_name(bufnr) ~= "" and not bigfile.is_active(bufnr) then
				gitsigns.attach({ bufnr = bufnr, trigger = trigger })
			end
		end

		local group = vim.api.nvim_create_augroup("RevazGitsigns", { clear = true })
		vim.api.nvim_create_autocmd(
			{ "BufFilePost", "BufRead", "BufNewFile", "BufWritePost", "FileType", "BufWinEnter" },
			{
				group = group,
				desc = "Attach Gitsigns only after shared large-file evaluation",
				callback = function(args)
					attach(args.buf, args.event)
				end,
			}
		)
		vim.api.nvim_create_autocmd({ "QuickFixCmdPre", "QuickFixCmdPost" }, {
			group = group,
			pattern = "*vimgrep*",
			desc = "Avoid Gitsigns attachment churn during vimgrep",
			callback = function(args)
				attach_disabled = args.event == "QuickFixCmdPre"
			end,
		})

		for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
			if vim.api.nvim_buf_is_loaded(bufnr) and vim.api.nvim_buf_get_name(bufnr) ~= "" then
				attach(bufnr, "setup")
			end
		end
	end,
}
