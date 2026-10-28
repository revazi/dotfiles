local M = {}

local group = vim.api.nvim_create_augroup("RevazAutoformat", { clear = false })

local biome_filetypes = {}
for _, filetype in ipairs(require("revaz.lsp.servers").servers.biome.filetypes) do
	biome_filetypes[filetype] = true
end

M.prettier_filetypes = {
	"css",
	"html",
	"javascript",
	"javascriptreact",
	"json",
	"jsonc",
	"less",
	"markdown",
	"markdown.mdx",
	"scss",
	"typescript",
	"typescriptreact",
	"yaml",
}

local fallback_filetypes = {
	lua = true,
	python = true,
}
for _, filetype in ipairs(M.prettier_filetypes) do
	fallback_filetypes[filetype] = true
end

local function has_biome_config(bufnr)
	local name = vim.api.nvim_buf_get_name(bufnr)
	return name ~= "" and vim.fs.root(name, { "biome.json", "biome.jsonc" }) ~= nil
end

function M.owner(bufnr)
	local filetype = vim.bo[bufnr].filetype
	if biome_filetypes[filetype] and has_biome_config(bufnr) then
		return "biome"
	end
	if fallback_filetypes[filetype] then
		return "null-ls"
	end
end

local function attached_formatting_client(bufnr, owner)
	local selected
	vim.api.nvim_buf_call(bufnr, function()
		for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
			if client.name == owner and client:supports_method("textDocument/formatting", bufnr) then
				selected = client
				return
			end
		end
	end)
	return selected
end

function M.attach(bufnr)
	vim.api.nvim_clear_autocmds({ group = group, buffer = bufnr })
	if not M.owner(bufnr) then
		return
	end

	vim.api.nvim_create_autocmd("BufWritePre", {
		group = group,
		buffer = bufnr,
		desc = "Format with the explicit buffer owner",
		callback = function()
			if vim.b[bufnr].disable_autoformat then
				return
			end

			local owner = M.owner(bufnr)
			if not owner then
				return
			end

			local client = attached_formatting_client(bufnr, owner)
			if not client then
				return
			end

			vim.api.nvim_buf_call(bufnr, function()
				vim.lsp.buf.format({
					async = false,
					bufnr = bufnr,
					filter = function(candidate)
						return candidate.id == client.id
					end,
				})
			end)
		end,
	})
end

return M
