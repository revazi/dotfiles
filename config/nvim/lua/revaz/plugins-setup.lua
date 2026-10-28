-- Set leader key early
vim.g.mapleader = ","

local preflight = require("revaz.preflight")

-- BOOTSTRAP lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	if not preflight.feature_available("lazy") then
		preflight.notify_missing("lazy-git", "lazy.nvim bootstrap skipped")
		return false
	end

	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
	if vim.v.shell_error ~= 0 or not vim.loop.fs_stat(lazypath) then
		vim.notify(
			"lazy.nvim bootstrap failed. Check Git/network access, remove any incomplete lazy.nvim directory, and restart Neovim.",
			vim.log.levels.ERROR
		)
		return false
	end
end

vim.opt.rtp:prepend(lazypath)

-- LOAD ALL PLUGINS FROM `lua/plugins/`
local status_ok, lazy = pcall(require, "lazy")
if not status_ok then
	vim.notify(
		"lazy.nvim could not be loaded. Run :ConfigHealth, then repair or reinstall its checkout.",
		vim.log.levels.ERROR
	)
	return false
end

lazy.setup("revaz.plugins", {
	rocks = {
		enabled = false,
	},
})

return true
