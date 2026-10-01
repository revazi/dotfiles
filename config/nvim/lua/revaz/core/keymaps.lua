-- Importing the required modules and setting up key mappings for Neovim.
local map = require("revaz.core.utils").map
local toggleNumber = require("revaz.core.utils").toggleNumber
local changeBackgroundColor = require("revaz.core.utils").changeBackgroundColor

---------------------
-- General Keymaps
---------------------

map("i", "jk", "<ESC>") -- exit insert mode
map("n", "<leader><CR>", ":luafile $MYVIMRC<CR>") -- reload config
map("n", "<leader>nh", ":nohl<CR>") -- clear search highlight
map("n", "x", '"_x') -- delete without yank

-- increment/decrement
map("n", "<leader>+", "<C-a>")
map("n", "<leader>-", "<C-x>")

-- window management
map("n", "<leader>sv", "<C-w>v")
map("n", "<leader>sh", "<C-w>s")
map("n", "<leader>se", "<C-w>=")
map("n", "<leader>sx", ":close<CR>")

-- tab management
map("n", "<leader>to", ":tabnew<CR>")
map("n", "<leader>tx", ":tabclose<CR>")
map("n", "<leader>tn", ":tabn<CR>")
map("n", "<leader>tp", ":tabp<CR>")

-- resize windows
map("n", "<Up>", "<C-w>5+")
map("n", "<Down>", "<C-w>5-")
map("n", "<Left>", "<C-w>5<")
map("n", "<Right>", "<C-w>5>")

-- Toggle line numbers
map("n", "<leader>n", "", {
	noremap = true,
	callback = toggleNumber,
	desc = "Toggle line numbers",
})

-- Toggle background color
map("n", "<leader>bg", "", {
	noremap = true,
	callback = changeBackgroundColor,
	desc = "Toggle background color",
})

---------------------
-- Plugin Keymaps
---------------------

-- vim-maximizer
map("n", "<leader>sm", ":MaximizerToggle<CR>")

-- nvim-tree
map("n", "<leader>e", ":NvimTreeToggle<CR>")

-- telescope
map("n", "<space>", "<cmd>Telescope find_files<CR>")
map("n", "<leader>ff", "<cmd>Telescope find_files<CR>")
map("n", "<leader>fs", "<cmd>Telescope live_grep<CR>")
map("n", "<leader>fc", "<cmd>Telescope grep_string<CR>")
map("n", "<leader>fb", "<cmd>Telescope buffers<CR>")
map("n", "<leader>fh", "<cmd>Telescope help_tags<CR>")
map("n", "<leader>gc", "<cmd>Telescope git_commits<CR>")
map("n", "<leader>gfc", "<cmd>Telescope git_bcommits<CR>")
map("n", "<leader>gb", "<cmd>Telescope git_branches<CR>")
map("n", "<leader>gs", "<cmd>Telescope git_status<CR>")

-- LSP
map("n", "<leader>rs", ":LspRestart<CR>")

-- Lspsaga (LSP UI)
map("n", "gf", "<cmd>Lspsaga lsp_finder<CR>")
map("n", "gD", "<cmd>lua vim.lsp.buf.declaration()<CR>")
map("n", "gd", "<cmd>Lspsaga peek_definition<CR>")
map("n", "gi", "<cmd>lua vim.lsp.buf.implementation()<CR>")
map("n", "<leader>ca", "<cmd>Lspsaga code_action<CR>")
map("n", "<leader>rn", "<cmd>Lspsaga rename<CR>")
map("n", "<leader>d", "<cmd>Lspsaga show_cursor_diagnostics<CR>")
map("n", "[d", "<cmd>Lspsaga diagnostic_jump_prev<CR>")
map("n", "]d", "<cmd>Lspsaga diagnostic_jump_next<CR>")
map("n", "K", "<cmd>Lspsaga hover_doc<CR>")
map("n", "<leader>o", "<cmd>LSoutlineToggle<CR>")

-- Typescript utilities
map("n", "<leader>rf", ":TypescriptRenameFile<CR>")
map("n", "<leader>oi", ":TypescriptOrganizeImports<CR>")
map("n", "<leader>ru", ":TypescriptRemoveUnused<CR>")

-- Claude Code Keymaps

-- Open Claude Code in split
vim.keymap.set("n", "<leader>cc", ":split | terminal claude code chat<CR>", { desc = "Claude Code Chat" })

-- Toggle Claude Code terminal
vim.keymap.set("n", "<leader>ct", function()
	local wins = vim.api.nvim_list_wins()
	for _, win in ipairs(wins) do
		local buf = vim.api.nvim_win_get_buf(win)
		local bufname = vim.api.nvim_buf_get_name(buf)
		if string.find(bufname, "claude") then
			vim.api.nvim_win_close(win, true)
			return
		end
	end
	vim.cmd("split | terminal claude code chat")
end, { desc = "Toggle Claude Code" })

-- Ask Claude about selected code (visual mode)
vim.keymap.set("v", "<leader>ca", function()
	local start_pos = vim.fn.getpos("'<")
	local end_pos = vim.fn.getpos("'>")
	local lines = vim.fn.getline(start_pos[2], end_pos[2])
	vim.fn.writefile(lines, "/tmp/claude_selection.txt")
	vim.cmd("split | terminal claude code chat --file /tmp/claude_selection.txt")
end, { desc = "Ask Claude about selection" })

-- Ask Claude about current file
vim.keymap.set("n", "<leader>cf", function()
	vim.cmd("split | terminal claude code chat --file " .. vim.fn.expand("%:p"))
end, { desc = "Ask Claude about file" })
