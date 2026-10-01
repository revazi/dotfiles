-- Add which-key to see your keybindings
-- File: lua/revaz/plugins/which-key.lua

return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	config = function()
		local wk = require("which-key")
		wk.setup({
			plugins = {
				marks = true,
				registers = true,
				spelling = {
					enabled = true,
					suggestions = 20,
				},
			},
			delay = 500, -- Wait 500ms before showing which-key
		})

		-- Register your existing keybindings with descriptions
		wk.add({
			-- General
			{ "<leader>+", desc = "Increment number" },
			{ "<leader>-", desc = "Decrement number" },
			{ "<leader><CR>", desc = "Reload config" },
			{ "<leader>bg", desc = "Toggle background" },
			{ "<leader>n", desc = "Toggle line numbers" },
			{ "<leader>nh", desc = "Clear search highlight" },

			-- Window management
			{ "<leader>s", group = "split/session" },
			{ "<leader>sv", desc = "Split vertical" },
			{ "<leader>sh", desc = "Split horizontal" },
			{ "<leader>se", desc = "Equal splits" },
			{ "<leader>sx", desc = "Close split" },
			{ "<leader>sm", desc = "Maximize toggle" },

			-- Tab management
			{ "<leader>t", group = "tabs" },
			{ "<leader>to", desc = "New tab" },
			{ "<leader>tx", desc = "Close tab" },
			{ "<leader>tn", desc = "Next tab" },
			{ "<leader>tp", desc = "Previous tab" },

			-- File explorer
			{ "<leader>e", desc = "Toggle file explorer" },

			-- Telescope/Find
			{ "<leader>f", group = "find" },
			{ "<leader>ff", desc = "Find files" },
			{ "<leader>fs", desc = "Search in files (live grep)" },
			{ "<leader>fc", desc = "Find word under cursor" },
			{ "<leader>fb", desc = "Find buffers" },
			{ "<leader>fh", desc = "Find help tags" },

			-- Git
			{ "<leader>g", group = "git" },
			{ "<leader>gc", desc = "Git commits" },
			{ "<leader>gfc", desc = "Git file commits" },
			{ "<leader>gb", desc = "Git branches" },
			{ "<leader>gs", desc = "Git status" },

			-- LSP
			{ "<leader>r", group = "refactor/rename" },
			{ "<leader>rs", desc = "Restart LSP" },
			{ "<leader>rn", desc = "Rename symbol" },
			{ "<leader>rf", desc = "Rename file (TS)" },
			{ "<leader>ru", desc = "Remove unused (TS)" },
			{ "<leader>ca", desc = "Code action / Ask Claude" },
			{ "<leader>d", desc = "Show diagnostics" },
			{ "<leader>o", desc = "Toggle outline" },
			{ "<leader>oi", desc = "Organize imports (TS)" },

			-- Claude Code
			{ "<leader>c", group = "claude/code" },
			{ "<leader>cc", desc = "Claude Code chat" },
			{ "<leader>ct", desc = "Toggle Claude Code" },
			{ "<leader>ca", desc = "Ask Claude (visual: selection, normal: code action)" },
			{ "<leader>cf", desc = "Ask Claude about file" },

			-- Notes (Telekasten)
			{ "<leader>n", group = "notes" },
			{ "<leader>nt", desc = "Today's note" },
			{ "<leader>nw", desc = "This week's note" },
			{ "<leader>ny", desc = "Yesterday's note" },
			{ "<leader>nn", desc = "New note" },
			{ "<leader>nN", desc = "New templated note" },
			{ "<leader>nf", desc = "Find notes" },
			{ "<leader>ns", desc = "Search in notes" },
			{ "<leader>ng", desc = "Follow link" },
			{ "<leader>np", desc = "Command panel" },
			{ "<leader>nc", desc = "Show calendar" },
			{ "<leader>n#", desc = "Show tags" },
			{ "<leader>nT", desc = "Toggle TODO" },
		})
	end,
}
