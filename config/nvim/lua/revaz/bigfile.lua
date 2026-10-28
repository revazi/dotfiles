local M = {}

M.thresholds = {
	markdown = 200 * 1024,
	general = 1024 * 1024,
}

local function is_markdown(bufnr, name)
	local filetype = vim.bo[bufnr].filetype
	if filetype == "" and name ~= "" then
		filetype = vim.filetype.match({ filename = name }) or ""
	end
	return filetype == "markdown" or filetype == "pandoc"
end

local function threshold_for(bufnr, name)
	if is_markdown(bufnr, name) then
		return M.thresholds.markdown, "markdown"
	end
	return M.thresholds.general, "general"
end

local function create_commands(bufnr)
	local function command(name, override, desc)
		vim.api.nvim_buf_create_user_command(bufnr, name, function()
			vim.b[bufnr].bigfile_override = override
			M.evaluate(bufnr)
		end, { desc = desc, force = true })
	end

	command("BigFileForce", "force", "Force large-file mode for this buffer")
	command("BigFileDisable", "disable", "Disable large-file mode for this buffer")
	command("BigFileAuto", "auto", "Use automatic large-file detection for this buffer")
end

local function disable_integrations(bufnr)
	vim.diagnostic.enable(false, { bufnr = bufnr })

	pcall(vim.treesitter.stop, bufnr)
	if vim.bo[bufnr].indentexpr == "v:lua.require'nvim-treesitter'.indentexpr()" then
		vim.bo[bufnr].indentexpr = vim.b[bufnr]._bigfile_saved_indentexpr or ""
	end

	local ok_formatting, formatting = pcall(require, "revaz.formatting")
	if ok_formatting then
		formatting.detach(bufnr)
	end

	for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
		vim.lsp.buf_detach_client(bufnr, client.id)
	end

	if package.loaded.cmp then
		require("cmp").abort()
	end
	if package.loaded.gitsigns then
		require("gitsigns").detach(bufnr)
	end
end

function M.is_active(bufnr)
	bufnr = bufnr or 0
	return vim.b[bufnr].bigfile == true
end

function M.evaluate(bufnr)
	bufnr = bufnr or 0
	if bufnr == 0 then
		bufnr = vim.api.nvim_get_current_buf()
	end
	if not vim.api.nvim_buf_is_valid(bufnr) then
		return false
	end

	create_commands(bufnr)

	local was_active = M.is_active(bufnr)
	local name = vim.api.nvim_buf_get_name(bufnr)
	local threshold, threshold_name = threshold_for(bufnr, name)
	local override = vim.b[bufnr].bigfile_override
	if override ~= "force" and override ~= "disable" then
		override = "auto"
	end

	local size
	local reason
	local active = false
	if override == "force" then
		active = true
		reason = "forced by b:bigfile_override"
	elseif override == "disable" then
		reason = "disabled by b:bigfile_override"
	elseif name == "" then
		reason = "unnamed buffer"
	else
		local stats = vim.uv.fs_stat(name)
		if not stats then
			reason = "file is not on disk"
		elseif stats.type ~= "file" then
			reason = "path is not a regular file"
		else
			size = stats.size
			active = size > threshold
			local comparison = active and "exceeds" or "is at or below"
			reason = ("size %d bytes %s %s threshold %d bytes"):format(size, comparison, threshold_name, threshold)
		end
	end

	vim.b[bufnr].bigfile = active
	vim.b[bufnr].bigfile_reason = reason
	vim.b[bufnr].bigfile_size = size or -1
	vim.b[bufnr].bigfile_threshold = threshold
	vim.b[bufnr].bigfile_threshold_name = threshold_name
	vim.b[bufnr].bigfile_override = override

	if active then
		if not was_active then
			vim.b[bufnr]._bigfile_diagnostics_was_enabled = vim.diagnostic.is_enabled({ bufnr = bufnr })
		end
		disable_integrations(bufnr)
	elseif was_active then
		-- Restore the buffer's prior diagnostics state after an override opts out.
		-- Integrations that were detached or skipped are intentionally not restarted.
		local diagnostics_was_enabled = vim.b[bufnr]._bigfile_diagnostics_was_enabled == true
		vim.diagnostic.enable(diagnostics_was_enabled, { bufnr = bufnr })
		vim.b[bufnr]._bigfile_diagnostics_was_enabled = nil
	end

	return active
end

function M.setup()
	local group = vim.api.nvim_create_augroup("RevazBigFile", { clear = true })
	vim.api.nvim_create_autocmd(
		{ "BufReadPre", "BufNewFile", "BufFilePost", "BufWritePost", "FileType", "BufWinEnter" },
		{
			group = group,
			desc = "Evaluate shared on-disk large-file state at early and post-modeline events",
			callback = function(args)
				M.evaluate(args.buf)
			end,
		}
	)

	M.evaluate(0)
end

return M
