-- UI fixes for terminal
vim.cmd([[
  if exists('$TMUX')
    let &t_8f = "<Esc>[38;2;%lu;%lu;%lum"
    let &t_8b = "<Esc>[48;2;%lu;%lu;%lum"
  endif
  set termguicolors
  set background=dark
]])

-- Our core/utils.lua file
local M = {}
local opt = vim.opt

function M.map(mode, lhs, rhs, opts)
	local options = { noremap = true }
	if opts then
		options = vim.tbl_extend("force", options, opts)
	end
	vim.api.nvim_set_keymap(mode, lhs, rhs, options)
end

function M.toggleNumber()
	local relativenumber = opt.relativenumber:get()
	local number = opt.number:get()
	if relativenumber and number then
		opt.relativenumber = true
		opt.number = false
	elseif relativenumber then
		opt.relativenumber = false
		opt.number = true
	elseif number then
		opt.relativenumber = false
		opt.number = false
	else
		opt.number = true
		opt.relativenumber = true
	end
end

function M.changeBackgroundColor()
	local background = opt.background:get()
	if background == "dark" then
		opt.background = "light"
		vim.cmd("colorscheme gruvbox-material") -- Set the light theme
	else
		opt.background = "dark"
		vim.cmd("colorscheme gruvbox-material") -- Set the dark theme
	end
end

return M
