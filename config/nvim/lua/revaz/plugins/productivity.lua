-- Minimal Setup: Claude Code + Telekasten
-- File: lua/revaz/plugins/productivity.lua

return {
	-- ============================================================================
	-- TELEKASTEN: Note-taking & Task Management
	-- ============================================================================
	{
		"renerocksai/telekasten.nvim",
		dependencies = { "nvim-telescope/telescope.nvim", "renerocksai/calendar-vim" },
		keys = {
			-- Daily notes
			{ "<leader>nt", "<cmd>Telekasten goto_today<cr>", desc = "Today's note" },
			{ "<leader>nw", "<cmd>Telekasten goto_thisweek<cr>", desc = "This week's note" },
			{ "<leader>ny", "<cmd>Telekasten goto_yesterday<cr>", desc = "Yesterday's note" },

			-- Find & search
			{ "<leader>nf", "<cmd>Telekasten find_notes<cr>", desc = "Find notes" },
			{ "<leader>ns", "<cmd>Telekasten search_notes<cr>", desc = "Search in notes" },
			{ "<leader>ng", "<cmd>Telekasten follow_link<cr>", desc = "Follow link" },

			-- Create
			{ "<leader>nn", "<cmd>Telekasten new_note<cr>", desc = "New note" },
			{ "<leader>nN", "<cmd>Telekasten new_templated_note<cr>", desc = "New note from template" },

			-- Panel & calendar
			{ "<leader>np", "<cmd>Telekasten panel<cr>", desc = "Command panel" },
			{ "<leader>nc", "<cmd>Telekasten show_calendar<cr>", desc = "Show calendar" },

			-- Tags
			{ "<leader>n#", "<cmd>Telekasten show_tags<cr>", desc = "Show tags" },
			{ "<leader>nT", "<cmd>Telekasten toggle_todo<cr>", desc = "Toggle TODO" },
		},
		config = function()
			require("telekasten").setup({
				home = vim.fn.expand("~/notes"),
				dailies = vim.fn.expand("~/notes/daily"),
				weeklies = vim.fn.expand("~/notes/weekly"),
				templates = vim.fn.expand("~/notes/templates"),
				template_new_note = vim.fn.expand("~/notes/templates/new_note.md"),
				template_new_daily = vim.fn.expand("~/notes/templates/daily.md"),
				template_new_weekly = vim.fn.expand("~/notes/templates/weekly.md"),
				extension = ".md",
				plug_into_calendar = true,
				calendar_opts = {
					weekdm = 1,
					calendar_monday = 1,
				},
				template_handling = "smart",
				auto_set_filetype = true,
				journal_auto_open = false,
			})
		end,
	},

	-- Calendar integration
	{
		"renerocksai/calendar-vim",
		lazy = true,
	},
}
