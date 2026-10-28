local startup_error = vim.v.errmsg

local function fail(message)
	error(message, 0)
end

local function assert_equal(actual, expected, message)
	if not vim.deep_equal(actual, expected) then
		fail(("%s (expected %s, got %s)"):format(message, vim.inspect(expected), vim.inspect(actual)))
	end
end

local function read_file(path)
	local file, err = io.open(path, "rb")
	if not file then
		fail(("could not read %s: %s"):format(path, err))
	end
	local contents = file:read("*a")
	file:close()
	return contents
end

local function write_bytes(path, size, prefix)
	prefix = prefix or ""
	if #prefix > size then
		fail(("fixture prefix is larger than requested size for %s"):format(path))
	end
	local file, err = io.open(path, "wb")
	if not file then
		fail(("could not write %s: %s"):format(path, err))
	end
	file:write(prefix)
	file:write(string.rep(" ", size - #prefix))
	file:close()
end

local function git_head(path)
	local output = vim.fn.system({ "git", "-C", path, "rev-parse", "HEAD" })
	if vim.v.shell_error ~= 0 then
		fail(("could not inspect plugin checkout %s: %s"):format(path, vim.trim(output)))
	end
	return vim.trim(output)
end

local function assert_no_obsolete_typescript_config(config_root, lock, plugins)
	if lock["typescript.nvim"] or plugins["typescript.nvim"] then
		fail("obsolete typescript.nvim is still present in the lockfile or plugin specs")
	end

	for path, kind in vim.fs.dir(config_root, { depth = math.huge }) do
		if kind == "file" and path:match("%.lua$") then
			local full_path = vim.fs.joinpath(config_root, path)
			local contents = read_file(full_path)
			if
				contents:find("jose%-elias%-alvarez/typescript%.nvim")
				or contents:find("require%s*%(?%s*[\"']typescript[\"']")
			then
				fail("obsolete typescript.nvim configuration found in " .. full_path)
			end
		end
	end
end

local function plugin_source(spec)
	if type(spec) == "string" then
		return spec
	end
	if type(spec) == "table" and type(spec[1]) == "string" then
		return spec[1]
	end
end

local function assert_primary_plugin_specs(config_root)
	local plugin_dir = config_root .. "/lua/revaz/plugins"
	local owners = {}

	for name, kind in vim.fs.dir(plugin_dir, { depth = math.huge }) do
		if kind == "file" and name:match("%.lua$") then
			local path = plugin_dir .. "/" .. name
			local chunk, load_error = loadfile(path)
			if not chunk then
				fail(("could not load plugin spec %s: %s"):format(path, load_error))
			end

			local ok, specs = pcall(chunk)
			if not ok then
				fail(("could not evaluate plugin spec %s: %s"):format(path, specs))
			end

			local primary_specs = plugin_source(specs) and { specs } or specs
			for _, spec in ipairs(primary_specs) do
				local source = plugin_source(spec)
				if source then
					if owners[source] then
						fail(
							("plugin %s has duplicate primary specs in %s and %s"):format(source, owners[source], path)
						)
					end
					owners[source] = path
				end
			end
		end
	end

	for _, obsolete in ipairs({ "cmp.lua", "lsp.lua", "lsp/mason-config.lua" }) do
		if vim.fn.filereadable(plugin_dir .. "/" .. obsolete) == 1 then
			fail("obsolete aggregate plugin module still exists: " .. obsolete)
		end
	end
end

local function assert_lsp_inventory()
	local inventory = require("revaz.lsp.servers")
	local expected = {
		"ansiblels",
		"bashls",
		"biome",
		"cssls",
		"dockerls",
		"emmet_ls",
		"eslint",
		"html",
		"lua_ls",
		"marksman",
		"pyright",
		"ruff",
		"tailwindcss",
		"ts_ls",
		"yamlls",
	}
	assert_equal(inventory.names(), expected, "configured LSP server inventory")
	assert_equal(inventory.mason_names(), expected, "Mason-managed LSP server inventory")

	for name, server in pairs(inventory.servers) do
		if server.mason ~= true then
			fail("configured LSP server is not Mason-managed: " .. name)
		end
		if type(server.cmd) ~= "table" or #server.cmd == 0 then
			fail("configured LSP server has no explicit command: " .. name)
		end
		if type(server.filetypes) ~= "table" or #server.filetypes == 0 then
			fail("configured LSP server has no supported filetypes: " .. name)
		end
	end

	assert_equal(inventory.servers.ts_ls.filetypes, {
		"javascript",
		"javascriptreact",
		"typescript",
		"typescriptreact",
	}, "ts_ls JavaScript and TypeScript filetypes")
	assert_equal(inventory.servers.biome.cmd, { "biome", "lsp-proxy" }, "Biome command")
	assert_equal(
		inventory.servers.ansiblels.system_dependencies,
		{ "ansible" },
		"Ansible language server system dependencies"
	)

	local function detected_filetype(path, lines)
		local bufnr = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_name(bufnr, path)
		vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines or {})
		local filetype = vim.filetype.match({ filename = path, buf = bufnr })
		vim.api.nvim_buf_delete(bufnr, { force = true })
		return filetype
	end

	local ansible_dir = vim.fn.stdpath("state") .. "/ansible-smoke"
	assert_equal(
		detected_filetype(ansible_dir .. "/site.yml", { "---", "- name: Configure web", "  hosts: web" }),
		"yaml.ansible",
		"Ansible playbook content filetype"
	)
	assert_equal(
		detected_filetype(ansible_dir .. "/roles/web/tasks/main.yml", { "---", "- name: Install package" }),
		"yaml.ansible",
		"Ansible role task filetype"
	)
	assert_equal(
		detected_filetype(ansible_dir .. "/playbooks/deploy.yaml"),
		"yaml.ansible",
		"Ansible playbook path filetype"
	)
	assert_equal(detected_filetype(ansible_dir .. "/config.yml", { "enabled: true" }), "yaml", "generic YAML filetype")
	assert_equal(
		vim.filetype.match({ filename = ansible_dir .. "/filename-only.yml" }),
		"yaml",
		"generic YAML filename-only filetype"
	)

	local state_dir = vim.fn.stdpath("state") .. "/lsp-smoke"
	local configured_dir = state_dir .. "/configured/src"
	local configured_jsonc_dir = state_dir .. "/configured-jsonc/src"
	local plain_dir = state_dir .. "/plain/src"
	vim.fn.mkdir(configured_dir, "p")
	vim.fn.mkdir(configured_jsonc_dir, "p")
	vim.fn.mkdir(plain_dir, "p")
	vim.fn.writefile({ "{}" }, state_dir .. "/configured/biome.json")
	vim.fn.writefile({ "{}" }, state_dir .. "/configured-jsonc/biome.jsonc")
	vim.fn.writefile({ "const configured = true" }, configured_dir .. "/configured.ts")
	vim.fn.writefile({ "const configuredJsonc = true" }, configured_jsonc_dir .. "/configured.ts")
	vim.fn.writefile({ "const plain = true" }, plain_dir .. "/plain.ts")

	local function detected_root(path)
		local root
		inventory.servers.biome.root_dir(path, function(dir)
			root = dir
		end)
		return root
	end

	assert_equal(
		detected_root(configured_dir .. "/configured.ts"),
		state_dir .. "/configured",
		"Biome configured-project root"
	)
	assert_equal(
		detected_root(configured_jsonc_dir .. "/configured.ts"),
		state_dir .. "/configured-jsonc",
		"Biome biome.jsonc project root"
	)
	assert_equal(
		detected_root(plain_dir .. "/plain.ts"),
		nil,
		"Biome must not attach without biome.json or biome.jsonc"
	)

	require("lazy").load({ plugins = { "nvim-lspconfig" } })
	for name, server in pairs(inventory.servers) do
		local configured = vim.lsp.config[name]
		if not configured then
			fail("native LSP configuration was not registered: " .. name)
		end
		assert_equal(configured.cmd, server.cmd, "native LSP command for " .. name)
		assert_equal(configured.filetypes, server.filetypes, "native LSP filetypes for " .. name)
		if not vim.lsp.is_enabled(name) then
			fail("native LSP configuration was not enabled: " .. name)
		end
	end

	local mason_settings = require("mason-lspconfig.settings").current
	assert_equal(mason_settings.automatic_enable, false, "mason-lspconfig automatic LSP activation")
	assert_equal(mason_settings.ensure_installed, {}, "smoke-mode Mason LSP installs")
	assert_equal(require("mason-null-ls.settings").current.ensure_installed, {}, "smoke-mode Mason none-ls installs")
end

local function assert_formatting_ownership()
	local formatting = require("revaz.formatting")
	local state_dir = vim.fn.stdpath("state") .. "/formatting-smoke"
	local biome_dir = state_dir .. "/biome/src"
	local plain_dir = state_dir .. "/plain/src"
	vim.fn.mkdir(biome_dir, "p")
	vim.fn.mkdir(plain_dir, "p")
	vim.fn.writefile({ "{}" }, state_dir .. "/biome/biome.json")

	local buffers = {}
	local function buffer(path, filetype)
		local bufnr = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_name(bufnr, path)
		vim.bo[bufnr].filetype = filetype
		table.insert(buffers, bufnr)
		return bufnr
	end

	local biome_typescript = buffer(biome_dir .. "/app.ts", "typescript")
	local plain_typescript = buffer(plain_dir .. "/app.ts", "typescript")
	local biome_python = buffer(biome_dir .. "/tool.py", "python")
	local generic_yaml = buffer(plain_dir .. "/config.yml", "yaml")
	local ansible_yaml = buffer(plain_dir .. "/playbook.yml", "yaml.ansible")
	local bash = buffer(plain_dir .. "/script.sh", "bash")
	local dockerfile = buffer(plain_dir .. "/Dockerfile", "dockerfile")

	assert_equal(formatting.owner(biome_typescript), "biome", "Biome project formatting owner")
	assert_equal(formatting.owner(plain_typescript), "null-ls", "TypeScript fallback formatting owner")
	assert_equal(formatting.owner(biome_python), "null-ls", "mixed-project Python formatting owner")
	assert_equal(formatting.owner(generic_yaml), "null-ls", "generic YAML formatting owner")
	assert_equal(formatting.owner(ansible_yaml), nil, "Ansible YAML formatting owner")
	assert_equal(formatting.owner(bash), nil, "Bash formatting owner")
	assert_equal(formatting.owner(dockerfile), nil, "Dockerfile formatting owner")

	local expected_prettier_filetypes = {
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
	assert_equal(formatting.prettier_filetypes, expected_prettier_filetypes, "Prettier fallback filetypes")
	for index, filetype in ipairs(expected_prettier_filetypes) do
		local fallback = buffer(("%s/fallback-%d"):format(plain_dir, index), filetype)
		assert_equal(formatting.owner(fallback), "null-ls", filetype .. " fallback formatting owner")
	end
	for index, filetype in ipairs(require("revaz.lsp.servers").servers.biome.filetypes) do
		local biome = buffer(("%s/biome-%d"):format(biome_dir, index), filetype)
		assert_equal(formatting.owner(biome), "biome", filetype .. " Biome formatting owner")
	end

	formatting.attach(plain_typescript)
	formatting.attach(biome_typescript)
	local function autocmd_count(bufnr)
		return #vim.api.nvim_get_autocmds({
			group = "RevazAutoformat",
			event = "BufWritePre",
			buffer = bufnr,
		})
	end
	assert_equal(autocmd_count(plain_typescript), 1, "first buffer formatting callback")
	assert_equal(autocmd_count(biome_typescript), 1, "second buffer formatting callback")

	formatting.attach(biome_typescript)
	formatting.attach(biome_typescript)
	assert_equal(autocmd_count(plain_typescript), 1, "reattachment preserved the first buffer callback")
	assert_equal(autocmd_count(biome_typescript), 1, "reattachment did not duplicate callbacks")

	formatting.attach(bash)
	assert_equal(autocmd_count(bash), 0, "unsupported filetype formatting callback")

	local calls = {}
	local notifications = {}
	local attached_by_buffer = {}
	local function client(id, name, supports_formatting)
		return {
			id = id,
			name = name,
			supports_method = function(_, method, requested_bufnr)
				assert_equal(method, "textDocument/formatting", name .. " capability method")
				assert_equal(requested_bufnr, vim.api.nvim_get_current_buf(), name .. " capability buffer context")
				return supports_formatting
			end,
		}
	end

	local null_ls = client(1, "null-ls", true)
	local duplicate_null_ls = client(2, "null-ls", true)
	local unsupported_null_ls = client(3, "null-ls", false)
	local biome = client(4, "biome", true)
	local ts_ls = client(5, "ts_ls", true)
	local original_format = vim.lsp.buf.format
	local original_get_clients = vim.lsp.get_clients
	local original_notify = vim.notify
	local ok, err = xpcall(function()
		vim.lsp.buf.format = function(options)
			table.insert(calls, options)
			return original_format(options)
		end
		vim.lsp.get_clients = function(options)
			return attached_by_buffer[options.bufnr] or {}
		end
		vim.notify = function(...)
			table.insert(notifications, { ... })
		end

		vim.api.nvim_set_current_buf(bash)
		attached_by_buffer[plain_typescript] = { ts_ls }
		attached_by_buffer[biome_typescript] = { null_ls, ts_ls }
		vim.api.nvim_exec_autocmds("BufWritePre", { group = "RevazAutoformat", buffer = plain_typescript })
		vim.api.nvim_exec_autocmds("BufWritePre", { group = "RevazAutoformat", buffer = biome_typescript })
		assert_equal(#calls, 0, "unattached selected owners do not format")
		assert_equal(#notifications, 0, "unattached selected owners stay quiet")

		vim.lsp.buf.format = function(options)
			assert_equal(vim.api.nvim_get_current_buf(), options.bufnr, "format invocation buffer context")
			table.insert(calls, options)
		end
		attached_by_buffer[plain_typescript] = { unsupported_null_ls, ts_ls }
		vim.api.nvim_exec_autocmds("BufWritePre", { group = "RevazAutoformat", buffer = plain_typescript })
		assert_equal(#calls, 0, "selected owner without formatting support does not format")
		assert_equal(#notifications, 0, "selected owner without formatting support stays quiet")

		attached_by_buffer[plain_typescript] = { null_ls, duplicate_null_ls, ts_ls, biome }
		attached_by_buffer[biome_typescript] = { biome, null_ls, ts_ls }
		vim.api.nvim_exec_autocmds("BufWritePre", { group = "RevazAutoformat", buffer = plain_typescript })
		assert_equal(#calls, 1, "fallback format invocation count")
		assert_equal(calls[1].async, false, "fallback formatting is synchronous")
		assert_equal(calls[1].bufnr, plain_typescript, "fallback format buffer")
		assert_equal(calls[1].filter(null_ls), true, "fallback owner filter")
		assert_equal(calls[1].filter(duplicate_null_ls), false, "fallback selects one exact owner client")
		assert_equal(calls[1].filter(ts_ls), false, "arbitrary LSP fallback filter")
		assert_equal(calls[1].filter(biome), false, "Biome excluded from fallback buffer")

		vim.api.nvim_exec_autocmds("BufWritePre", { group = "RevazAutoformat", buffer = biome_typescript })
		assert_equal(#calls, 2, "Biome format invocation count")
		assert_equal(calls[2].async, false, "Biome formatting is synchronous")
		assert_equal(calls[2].bufnr, biome_typescript, "Biome format buffer")
		assert_equal(calls[2].filter(biome), true, "Biome owner filter")
		assert_equal(calls[2].filter(null_ls), false, "none-ls excluded from Biome buffer")
		assert_equal(calls[2].filter(ts_ls), false, "arbitrary LSP Biome filter")
		assert_equal(#notifications, 0, "attached selected owners stay quiet")

		vim.b[plain_typescript].disable_autoformat = true
		vim.api.nvim_exec_autocmds("BufWritePre", { group = "RevazAutoformat", buffer = plain_typescript })
		assert_equal(#calls, 2, "buffer-local formatting opt-out")
		vim.b[plain_typescript].disable_autoformat = false
		vim.api.nvim_exec_autocmds("BufWritePre", { group = "RevazAutoformat", buffer = plain_typescript })
		assert_equal(#calls, 3, "buffer-local formatting opt-out re-enable")
	end, debug.traceback)
	vim.lsp.buf.format = original_format
	vim.lsp.get_clients = original_get_clients
	vim.notify = original_notify

	for _, bufnr in ipairs(buffers) do
		vim.api.nvim_buf_delete(bufnr, { force = true })
	end
	if not ok then
		fail(err)
	end

	local none_ls_config = read_file(vim.env.DOTFILES_NVIM_SOURCE .. "/lua/revaz/plugins/none-ls.lua")
	if none_ls_config:find("vim.notify", 1, true) then
		fail("none-ls configuration contains routine notifications")
	end
	if none_ls_config:find("debug = true", 1, true) or none_ls_config:find('log_level = "debug"', 1, true) then
		fail("none-ls debug logging is enabled")
	end
end

local function assert_locked_plugins()
	local config_root = vim.fn.stdpath("config")
	local staged_lock = read_file(config_root .. "/lazy-lock.json")
	local canonical_lock = read_file(vim.env.DOTFILES_NVIM_SOURCE .. "/lazy-lock.json")
	assert_equal(staged_lock, canonical_lock, "lazy.nvim changed the committed lockfile during startup")
	local lock = vim.json.decode(canonical_lock)
	local plugins = require("lazy.core.config").plugins
	local locked_count = 0

	for name, plugin in pairs(plugins) do
		if plugin.url then
			local entry = lock[name]
			if not entry then
				fail("plugin spec has no lazy-lock.json entry: " .. name)
			end
			if not plugin.dir or vim.fn.isdirectory(plugin.dir) ~= 1 then
				fail("locked plugin is not installed: " .. name)
			end
			assert_equal(git_head(plugin.dir), entry.commit, "plugin checkout is not locked: " .. name)
			locked_count = locked_count + 1
		end
	end

	for name in pairs(lock) do
		if not plugins[name] then
			fail("lazy-lock.json contains no matching plugin spec: " .. name)
		end
	end

	if locked_count == 0 then
		fail("no locked plugins were discovered")
	end

	assert_no_obsolete_typescript_config(config_root, lock, plugins)
	assert_primary_plugin_specs(config_root)
	return locked_count
end

local function assert_bigfile_mode()
	local bigfile = require("revaz.bigfile")
	assert_equal(bigfile.thresholds.markdown, 200 * 1024, "Markdown large-file threshold")
	assert_equal(bigfile.thresholds.general, 1024 * 1024, "general large-file threshold")

	local install = require("nvim-treesitter").install({ "lua", "markdown", "markdown_inline" })
	install:wait(120000)

	local state_dir = vim.fn.stdpath("state") .. "/bigfile-smoke"
	vim.fn.mkdir(state_dir, "p")
	local fixtures = {
		markdown_below = { path = state_dir .. "/markdown-below.md", size = bigfile.thresholds.markdown - 1 },
		markdown_exact = { path = state_dir .. "/markdown-exact.md", size = bigfile.thresholds.markdown },
		markdown_above = { path = state_dir .. "/markdown-above.md", size = bigfile.thresholds.markdown + 1 },
		general_below = { path = state_dir .. "/general-below.lua", size = bigfile.thresholds.general - 1 },
		general_exact = { path = state_dir .. "/general-exact.lua", size = bigfile.thresholds.general },
		general_above = { path = state_dir .. "/general-above.lua", size = bigfile.thresholds.general + 1 },
	}
	for name, fixture in pairs(fixtures) do
		local prefix = name:find("markdown", 1, true) and "# fixture\n" or "-- fixture\n"
		write_bytes(fixture.path, fixture.size, prefix)
	end

	local function edit(fixture)
		vim.cmd.edit(vim.fn.fnameescape(fixture.path))
		fixture.bufnr = vim.api.nvim_get_current_buf()
		return fixture.bufnr
	end

	local function assert_state(fixture, expected, threshold_name, message)
		local bufnr = edit(fixture)
		assert_equal(vim.b[bufnr].bigfile, expected, message .. " active state")
		assert_equal(vim.b[bufnr].bigfile_size, fixture.size, message .. " byte size")
		assert_equal(vim.b[bufnr].bigfile_threshold, bigfile.thresholds[threshold_name], message .. " threshold")
		assert_equal(vim.b[bufnr].bigfile_threshold_name, threshold_name, message .. " threshold name")
		assert_equal(vim.b[bufnr].bigfile_override, "auto", message .. " automatic override state")
		local comparison = expected and "exceeds" or "is at or below"
		assert_equal(
			vim.b[bufnr].bigfile_reason,
			("size %d bytes %s %s threshold %d bytes"):format(
				fixture.size,
				comparison,
				threshold_name,
				bigfile.thresholds[threshold_name]
			),
			message .. " reason"
		)
		return bufnr
	end

	assert_state(fixtures.markdown_below, false, "markdown", "Markdown below boundary")
	local markdown_exact = assert_state(fixtures.markdown_exact, false, "markdown", "Markdown exact boundary")
	local markdown_above = assert_state(fixtures.markdown_above, true, "markdown", "Markdown above boundary")
	assert_state(fixtures.general_below, false, "general", "general below boundary")
	local general_exact = assert_state(fixtures.general_exact, false, "general", "general exact boundary")
	local general_above = assert_state(fixtures.general_above, true, "general", "general above boundary")

	assert_equal(vim.bo[markdown_exact].filetype, "markdown", "Markdown fixture filetype")
	assert_equal(vim.bo[general_exact].filetype, "lua", "generic fixture filetype")
	for _, normal_bufnr in ipairs({ markdown_exact, general_exact }) do
		assert_equal(vim.diagnostic.is_enabled({ bufnr = normal_bufnr }), true, "normal-buffer diagnostics")
		if
			not vim.wait(5000, function()
				return vim.treesitter.highlighter.active[normal_bufnr] ~= nil
			end, 50)
		then
			fail("Treesitter did not activate at a normal-size threshold boundary")
		end
	end
	for _, large_bufnr in ipairs({ markdown_above, general_above }) do
		if vim.treesitter.highlighter.active[large_bufnr] ~= nil then
			fail("Treesitter activated for a large-file buffer")
		end
		assert_equal(vim.diagnostic.is_enabled({ bufnr = large_bufnr }), false, "large-file diagnostics")
		assert_equal(#vim.lsp.get_clients({ bufnr = large_bufnr }), 0, "large-file LSP clients")
	end

	local post_modeline_autocmds = vim.api.nvim_get_autocmds({
		group = "RevazBigFile",
		event = "BufWinEnter",
	})
	assert_equal(#post_modeline_autocmds, 1, "post-modeline large-file reevaluation")

	local modeline_path = state_dir .. "/modeline-markdown.lua"
	local modeline_size = bigfile.thresholds.markdown + 1
	write_bytes(modeline_path, modeline_size, "-- vim: set ft=markdown :\n")
	vim.cmd.edit(vim.fn.fnameescape(modeline_path))
	local modeline_bufnr = vim.api.nvim_get_current_buf()
	assert_equal(vim.bo[modeline_bufnr].filetype, "markdown", "modeline final filetype")
	assert_equal(vim.b[modeline_bufnr].bigfile, true, "modeline Markdown large-file state")
	assert_equal(vim.b[modeline_bufnr].bigfile_threshold_name, "markdown", "modeline Markdown threshold")
	assert_equal(vim.b[modeline_bufnr].bigfile_size, modeline_size, "modeline Markdown byte size")
	assert_equal(vim.treesitter.highlighter.active[modeline_bufnr], nil, "modeline large-file Treesitter prevention")
	assert_equal(
		vim.diagnostic.is_enabled({ bufnr = modeline_bufnr }),
		false,
		"modeline large-file diagnostics prevention"
	)

	local unnamed = vim.api.nvim_create_buf(false, true)
	bigfile.evaluate(unnamed)
	assert_equal(vim.b[unnamed].bigfile, false, "unnamed buffer active state")
	assert_equal(vim.b[unnamed].bigfile_reason, "unnamed buffer", "unnamed buffer reason")
	assert_equal(vim.b[unnamed].bigfile_size, -1, "unnamed buffer byte size")
	vim.api.nvim_buf_delete(unnamed, { force = true })

	local new_path = state_dir .. "/new-file.lua"
	vim.cmd.edit(vim.fn.fnameescape(new_path))
	local new_bufnr = vim.api.nvim_get_current_buf()
	assert_equal(vim.b[new_bufnr].bigfile, false, "new file active state")
	assert_equal(vim.b[new_bufnr].bigfile_reason, "file is not on disk", "new file reason")

	local lsp_root_dir = state_dir .. "/lsp-roots"
	local deno_dir = lsp_root_dir .. "/deno"
	vim.fn.mkdir(deno_dir, "p")
	vim.fn.writefile({ "{}" }, lsp_root_dir .. "/package-lock.json")
	vim.fn.writefile({ "module.exports = {}" }, lsp_root_dir .. "/tailwind.config.js")
	vim.fn.writefile({ "export const fixture = true" }, lsp_root_dir .. "/fixture.ts")
	vim.fn.writefile({ "{}" }, deno_dir .. "/deno.json")
	vim.fn.writefile({ "export const denoFixture = true" }, deno_dir .. "/fixture.ts")

	local function named_buffer(path, filetype)
		local bufnr = vim.api.nvim_create_buf(false, false)
		vim.api.nvim_buf_set_name(bufnr, path)
		vim.bo[bufnr].filetype = filetype
		bigfile.evaluate(bufnr)
		return bufnr
	end

	local project_bufnr = named_buffer(lsp_root_dir .. "/fixture.ts", "typescript")
	local tailwind_root
	vim.lsp.config.tailwindcss.root_dir(project_bufnr, function(root)
		tailwind_root = root
	end)
	assert_equal(tailwind_root, lsp_root_dir, "Tailwind keeps nvim-lspconfig root resolution")

	local ts_root
	vim.lsp.config.ts_ls.root_dir(project_bufnr, function(root)
		ts_root = root
	end)
	assert_equal(ts_root, lsp_root_dir, "ts_ls keeps nvim-lspconfig project root resolution")

	local deno_bufnr = named_buffer(deno_dir .. "/fixture.ts", "typescript")
	local deno_root_calls = 0
	vim.lsp.config.ts_ls.root_dir(deno_bufnr, function()
		deno_root_calls = deno_root_calls + 1
	end)
	assert_equal(deno_root_calls, 0, "ts_ls keeps nvim-lspconfig Deno exclusion")
	vim.api.nvim_buf_delete(project_bufnr, { force = true })
	vim.api.nvim_buf_delete(deno_bufnr, { force = true })

	local lua_config = vim.lsp.config.lua_ls
	local normal_root_calls = 0
	lua_config.root_dir(general_exact, function()
		normal_root_calls = normal_root_calls + 1
	end)
	assert_equal(normal_root_calls, 1, "normal-buffer native LSP gate")
	for _, name in ipairs(require("revaz.lsp.servers").names()) do
		local large_root_calls = 0
		vim.lsp.config[name].root_dir(general_above, function()
			large_root_calls = large_root_calls + 1
		end)
		assert_equal(large_root_calls, 0, "large-file native LSP gate for " .. name)
	end

	require("lazy").load({ plugins = { "none-ls", "nvim-cmp", "gitsigns.nvim" } })
	local none_ls_should_attach = require("null-ls.config").get().should_attach
	assert_equal(none_ls_should_attach(general_exact), true, "normal-buffer none-ls gate")
	assert_equal(none_ls_should_attach(general_above), false, "large-file none-ls gate")

	vim.api.nvim_set_current_buf(general_above)
	assert_equal(require("cmp.config").get().enabled(), false, "large-file completion gate")
	vim.api.nvim_set_current_buf(general_exact)
	assert_equal(require("cmp.config").get().enabled(), true, "normal-buffer completion gate")

	local gitsigns = require("gitsigns")
	local gitsigns_config = require("gitsigns.config").config
	assert_equal(gitsigns_config.auto_attach, false, "Gitsigns built-in automatic attachment")
	assert_equal(gitsigns_config.on_attach(general_exact), true, "normal-buffer Gitsigns final veto")
	assert_equal(gitsigns_config.on_attach(general_above), false, "large-file Gitsigns final veto")
	local original_gitsigns_attach = gitsigns.attach
	local gitsigns_calls = {}
	gitsigns.attach = function(options)
		table.insert(gitsigns_calls, options)
	end
	vim.api.nvim_exec_autocmds("BufWritePost", { group = "RevazGitsigns", buffer = general_above })
	assert_equal(#gitsigns_calls, 0, "large-file Gitsigns gate")
	vim.api.nvim_exec_autocmds("BufWritePost", { group = "RevazGitsigns", buffer = general_exact })
	assert_equal(#gitsigns_calls, 1, "normal-buffer Gitsigns gate")
	assert_equal(gitsigns_calls[1].bufnr, general_exact, "normal-buffer Gitsigns target")
	gitsigns.attach = original_gitsigns_attach

	local formatting = require("revaz.formatting")
	local function formatting_autocmd_count(bufnr)
		return #vim.api.nvim_get_autocmds({
			group = "RevazAutoformat",
			event = "BufWritePre",
			buffer = bufnr,
		})
	end
	formatting.attach(general_above)
	assert_equal(formatting_autocmd_count(general_above), 0, "large-file automatic formatting gate")

	vim.api.nvim_set_current_buf(fixtures.general_below.bufnr)
	formatting.attach(fixtures.general_below.bufnr)
	assert_equal(formatting_autocmd_count(fixtures.general_below.bufnr), 1, "normal-buffer automatic formatting")

	local original_get_clients = vim.lsp.get_clients
	local original_detach_client = vim.lsp.buf_detach_client
	local original_gitsigns_detach = gitsigns.detach
	local detached_clients = {}
	local detached_gitsigns = {}
	vim.lsp.get_clients = function(options)
		if options.bufnr == fixtures.general_below.bufnr then
			return { { id = 101, name = "lua_ls" }, { id = 102, name = "null-ls" } }
		end
		return original_get_clients(options)
	end
	vim.lsp.buf_detach_client = function(bufnr, client_id)
		table.insert(detached_clients, { bufnr = bufnr, client_id = client_id })
	end
	gitsigns.detach = function(bufnr)
		table.insert(detached_gitsigns, bufnr)
	end
	vim.cmd.BigFileForce()
	vim.lsp.get_clients = original_get_clients
	vim.lsp.buf_detach_client = original_detach_client
	gitsigns.detach = original_gitsigns_detach

	assert_equal(vim.b.bigfile, true, "forced large-file state")
	assert_equal(vim.b.bigfile_override, "force", "forced override state")
	assert_equal(vim.b.bigfile_reason, "forced by b:bigfile_override", "forced override reason")
	assert_equal(formatting_autocmd_count(fixtures.general_below.bufnr), 0, "forced large-file formatting removal")
	assert_equal(vim.treesitter.highlighter.active[fixtures.general_below.bufnr], nil, "forced Treesitter stop")
	if vim.bo[fixtures.general_below.bufnr].indentexpr:find("nvim%-treesitter") then
		fail("forced large-file mode retained Treesitter indent")
	end
	assert_equal(vim.diagnostic.is_enabled({ bufnr = fixtures.general_below.bufnr }), false, "forced diagnostics stop")
	assert_equal(require("cmp.config").get().enabled(), false, "forced completion stop")
	assert_equal(detached_clients, {
		{ bufnr = fixtures.general_below.bufnr, client_id = 101 },
		{ bufnr = fixtures.general_below.bufnr, client_id = 102 },
	}, "forced native and none-ls client detachment")
	assert_equal(detached_gitsigns, { fixtures.general_below.bufnr }, "forced Gitsigns detachment")

	vim.cmd.BigFileDisable()
	assert_equal(vim.b.bigfile, false, "disabled large-file state")
	assert_equal(vim.b.bigfile_override, "disable", "disabled override state")
	assert_equal(vim.b.bigfile_reason, "disabled by b:bigfile_override", "disabled override reason")
	assert_equal(
		vim.diagnostic.is_enabled({ bufnr = fixtures.general_below.bufnr }),
		true,
		"override diagnostics resume"
	)
	assert_equal(require("cmp.config").get().enabled(), true, "override completion resume")
	assert_equal(
		vim.treesitter.highlighter.active[fixtures.general_below.bufnr],
		nil,
		"override does not silently restart Treesitter"
	)
	assert_equal(
		formatting_autocmd_count(fixtures.general_below.bufnr),
		0,
		"override does not silently restart formatting"
	)

	vim.cmd.BigFileAuto()
	assert_equal(vim.b.bigfile, false, "automatic override restored state")
	assert_equal(vim.b.bigfile_override, "auto", "automatic override value")

	vim.diagnostic.enable(false, { bufnr = fixtures.general_below.bufnr })
	vim.cmd.BigFileForce()
	vim.cmd.BigFileDisable()
	assert_equal(
		vim.diagnostic.is_enabled({ bufnr = fixtures.general_below.bufnr }),
		false,
		"override preserves a pre-existing diagnostics opt-out"
	)
	vim.diagnostic.enable(true, { bufnr = fixtures.general_below.bufnr })

	local race_dir = state_dir .. "/gitsigns-race"
	vim.fn.delete(race_dir, "rf")
	vim.fn.mkdir(race_dir, "p")
	local function run_git(arguments, message)
		local command = { "git", "-C", race_dir }
		vim.list_extend(command, arguments)
		local output = vim.fn.system(command)
		if vim.v.shell_error ~= 0 then
			fail(("%s: %s"):format(message, vim.trim(output)))
		end
	end
	run_git({ "init", "--quiet" }, "could not initialize Gitsigns race fixture")
	local race_path = race_dir .. "/tracked.lua"
	vim.fn.writefile({ "return true" }, race_path)
	run_git({ "add", "tracked.lua" }, "could not stage Gitsigns race fixture")

	local reverse_modeline_path = race_dir .. "/reverse-modeline.md"
	local reverse_modeline_size = bigfile.thresholds.markdown + 1
	write_bytes(reverse_modeline_path, reverse_modeline_size, "-- vim: set ft=lua :\n")
	run_git({ "add", "reverse-modeline.md" }, "could not stage reverse-modeline Gitsigns fixture")
	vim.cmd.edit(vim.fn.fnameescape(reverse_modeline_path))
	local reverse_modeline_bufnr = vim.api.nvim_get_current_buf()
	assert_equal(vim.bo[reverse_modeline_bufnr].filetype, "lua", "reverse modeline final filetype")
	assert_equal(vim.b[reverse_modeline_bufnr].bigfile, false, "reverse modeline final normal-size state")
	assert_equal(vim.b[reverse_modeline_bufnr].bigfile_threshold_name, "general", "reverse modeline threshold")
	if
		not vim.wait(5000, function()
			return require("gitsigns.cache").cache[reverse_modeline_bufnr] ~= nil
		end, 10)
	then
		fail("Gitsigns did not attach after a modeline changed Markdown-large to generic-normal")
	end
	vim.api.nvim_buf_delete(reverse_modeline_bufnr, { force = true })

	local race_bufnr = vim.api.nvim_create_buf(false, false)
	vim.api.nvim_buf_set_lines(race_bufnr, 0, -1, false, { "return true" })
	vim.bo[race_bufnr].filetype = "lua"

	local original_on_attach_pre = gitsigns_config._on_attach_pre
	local original_on_attach = gitsigns_config.on_attach
	local continue_attach
	local final_veto_calls = 0
	gitsigns_config._on_attach_pre = function(bufnr, callback)
		assert_equal(bufnr, race_bufnr, "in-flight Gitsigns target")
		continue_attach = callback
	end
	gitsigns_config.on_attach = function(bufnr)
		if bufnr == race_bufnr then
			final_veto_calls = final_veto_calls + 1
		end
		return original_on_attach(bufnr)
	end

	-- Naming the loaded buffer triggers the configured asynchronous attachment.
	vim.api.nvim_buf_set_name(race_bufnr, race_path)
	vim.api.nvim_set_current_buf(race_bufnr)
	if not vim.wait(5000, function()
		return continue_attach ~= nil
	end, 10) then
		fail("Gitsigns did not reach its asynchronous pre-attach hook")
	end

	vim.cmd.BigFileForce()
	continue_attach({})
	if not vim.wait(5000, function()
		return final_veto_calls == 1
	end, 10) then
		fail("Gitsigns in-flight attachment did not reach its final veto")
	end
	gitsigns_config._on_attach_pre = original_on_attach_pre
	gitsigns_config.on_attach = original_on_attach
	assert_equal(require("gitsigns.cache").cache[race_bufnr], nil, "Gitsigns in-flight final veto")
	vim.cmd.BigFileDisable()
	vim.api.nvim_buf_delete(race_bufnr, { force = true })

	local treesitter_config = read_file(vim.env.DOTFILES_NVIM_SOURCE .. "/lua/revaz/plugins/treesitter.lua")
	if treesitter_config:find("fs_stat", 1, true) or treesitter_config:find("200 * 1024", 1, true) then
		fail("Treesitter retains duplicate Markdown size detection")
	end
end

local function assert_preflight(config_root)
	local preflight = require("revaz.preflight")
	assert_equal(preflight.meets_minimum({ major = 0, minor = 11, patch = 9 }), false, "Neovim minimum guard")
	assert_equal(preflight.meets_minimum({ major = 0, minor = 12, patch = 0 }), true, "Neovim minimum acceptance")
	if vim.fn.exists(":ConfigHealth") ~= 2 then
		fail(":ConfigHealth was not registered")
	end

	local inventory = {}
	for _, item in ipairs(preflight.inventory()) do
		inventory[item.id] = item
	end
	assert_equal(inventory["lazy-git"].category, "required", "lazy.nvim Git dependency category")
	assert_equal(inventory["treesitter-cli"].category, "optional", "Tree-sitter CLI dependency category")
	assert_equal(inventory["copilot-node"].category, "optional", "Copilot Node dependency category")
	if
		not inventory["mason-download"]
		or not inventory["mason-tar"]
		or not inventory["mason-unzip"]
		or not inventory["mason-gzip"]
	then
		fail("configuration dependency inventory does not cover Mason download and extraction tools")
	end
	if not inventory["lsp-ts_ls"] or not inventory["none-ls-prettier"] then
		fail("configuration dependency inventory does not cover LSP and none-ls executables")
	end

	local options = read_file(config_root .. "/lua/revaz/core/options.lua")
	if options:find("python3_host_prog", 1, true) or options:find("/Users/", 1, true) then
		fail("core options retain a machine-specific Python provider path")
	end

	local original_overrides = vim.g.revaz_preflight_overrides
	local original_notify = vim.notify
	local notifications = {}
	vim.notify = function(message)
		table.insert(notifications, message)
	end
	local missing_executables = {
		git = false,
		["tree-sitter"] = false,
		rg = false,
		node = false,
		fd = false,
		fdfind = false,
		find = true,
		make = false,
		curl = false,
		wget = false,
		tar = false,
		gtar = false,
		unzip = false,
		gzip = false,
		cc = false,
		clang = false,
		gcc = false,
	}
	vim.g.revaz_preflight_overrides = { executables = missing_executables }

	assert_equal(preflight.feature_available("lazy"), false, "missing Git bootstrap gate")
	assert_equal(preflight.feature_available("treesitter"), false, "missing Tree-sitter toolchain gate")
	assert_equal(preflight.feature_available("telescope_files"), true, "Telescope find fallback")
	assert_equal(preflight.feature_available("telescope_grep"), false, "missing ripgrep gate")
	assert_equal(preflight.feature_available("fzf-native"), false, "missing native-build tool gate")
	assert_equal(preflight.feature_available("copilot"), false, "missing Node Copilot gate")

	vim.g.revaz_preflight_overrides = {
		executables = { make = true, cc = false, clang = true },
		environment = { CC = false },
	}
	assert_equal(preflight.feature_available("fzf-native"), false, "fzf-native requires make's default cc")
	vim.g.revaz_preflight_overrides = {
		executables = { make = true, cc = false, clang = true },
		environment = { CC = "clang" },
	}
	assert_equal(preflight.feature_available("fzf-native"), true, "fzf-native honors an executable CC override")
	vim.g.revaz_preflight_overrides = {
		executables = { make = true, ccache = true, clang = false },
		environment = { CC = "ccache clang" },
	}
	assert_equal(preflight.feature_available("fzf-native"), false, "fzf-native checks a wrapped compiler command")
	vim.g.revaz_preflight_overrides = {
		executables = { make = true, ccache = true, clang = true },
		environment = { CC = "ccache clang" },
	}
	assert_equal(preflight.feature_available("fzf-native"), true, "fzf-native accepts an available wrapped compiler")
	for _, compiler in ipairs({ "cl", "clang-cl" }) do
		vim.g.revaz_preflight_overrides = {
			executables = { make = true, [compiler] = true },
			environment = { CC = compiler },
		}
		assert_equal(
			preflight.feature_available("fzf-native"),
			false,
			"fzf-native rejects MSVC-style " .. compiler .. " on non-Windows"
		)
	end
	vim.g.revaz_preflight_overrides = {
		executables = { make = true, zig = true },
		environment = { CC = "zig" },
	}
	assert_equal(preflight.feature_available("fzf-native"), false, "fzf-native rejects bare zig as a C compiler")
	vim.g.revaz_preflight_overrides = {
		executables = { make = true, zig = true },
		environment = { CC = "zig cc" },
	}
	assert_equal(preflight.feature_available("fzf-native"), true, "fzf-native accepts zig's C compiler command")

	local original_system = vim.system
	local waited_for
	vim.system = function()
		return {
			wait = function(_, timeout)
				waited_for = timeout
				return { code = 124, stdout = "", stderr = "" }
			end,
		}
	end
	package.loaded["revaz.preflight"] = nil
	local bounded_preflight = require("revaz.preflight")
	vim.g.revaz_preflight_overrides = {
		executables = { ["tree-sitter"] = true, curl = true, tar = true, cc = true },
	}
	assert_equal(bounded_preflight.feature_available("treesitter"), false, "timed-out Tree-sitter version probe")
	assert_equal(waited_for, bounded_preflight.version_probe_timeout_ms, "Tree-sitter version probe timeout")
	package.loaded["revaz.preflight"] = preflight
	vim.system = original_system

	local treesitter = require("nvim-treesitter")
	local install_calls = 0
	package.loaded["nvim-treesitter"] = {
		install = function()
			install_calls = install_calls + 1
		end,
		indentexpr = treesitter.indentexpr,
	}
	local treesitter_spec = dofile(config_root .. "/lua/revaz/plugins/treesitter.lua")
	local original_cmd = vim.cmd
	local update_calls = 0
	vim.cmd = function(command)
		if command == "TSUpdate" then
			update_calls = update_calls + 1
		end
	end

	local treesitter_cases = {
		{
			name = "missing CLI",
			executables = { ["tree-sitter"] = false, curl = true, tar = true, cc = true },
			version = "0.27.0",
		},
		{
			name = "outdated CLI",
			executables = { ["tree-sitter"] = true, curl = true, tar = true, cc = true },
			version = "0.25.0",
		},
		{
			name = "missing curl",
			executables = { ["tree-sitter"] = true, curl = false, tar = true, cc = true },
			version = "0.27.0",
		},
		{
			name = "missing tar",
			executables = { ["tree-sitter"] = true, curl = true, tar = false, cc = true },
			version = "0.27.0",
		},
		{
			name = "missing compiler",
			executables = {
				["tree-sitter"] = true,
				curl = true,
				tar = true,
				cc = false,
				clang = false,
				gcc = false,
			},
			version = "0.27.0",
		},
		{
			name = "missing configured compiler",
			executables = {
				["tree-sitter"] = true,
				curl = true,
				tar = true,
				cc = true,
				["missing-compiler"] = false,
			},
			environment = { CC = "missing-compiler" },
			version = "0.27.0",
		},
	}
	for _, case in ipairs(treesitter_cases) do
		vim.g.revaz_preflight_overrides = {
			executables = case.executables,
			environment = case.environment,
			versions = { ["tree-sitter"] = case.version },
		}
		assert_equal(preflight.feature_available("treesitter"), false, "Tree-sitter gate: " .. case.name)
		if case.name == "outdated CLI" then
			local _, missing = preflight.status(preflight.find("treesitter-cli"))
			if not table.concat(missing, ", "):find("0.26.1 or newer", 1, true) then
				fail("outdated Tree-sitter CLI status omitted the minimum supported version")
			end
		end
		treesitter_spec.build()
		treesitter_spec.config()
	end
	vim.cmd = original_cmd
	package.loaded["nvim-treesitter"] = treesitter
	assert_equal(update_calls, 0, "Tree-sitter updates skipped with incomplete toolchains")
	assert_equal(install_calls, 0, "Tree-sitter installs skipped with incomplete toolchains")
	if
		not vim.iter(notifications):any(function(message)
			return message:find("Tree-sitter parser update skipped", 1, true) ~= nil
				and message:find("tree-sitter CLI 0.26.1 or newer", 1, true) ~= nil
		end)
	then
		fail("incomplete Tree-sitter toolchain did not produce one actionable parser report")
	end

	vim.g.revaz_preflight_overrides = { executables = missing_executables }

	local telescope_calls = { find_files = 0, live_grep = 0 }
	local original_builtin = package.loaded["telescope.builtin"]
	package.loaded["telescope.builtin"] = {
		find_files = function()
			telescope_calls.find_files = telescope_calls.find_files + 1
		end,
		live_grep = function()
			telescope_calls.live_grep = telescope_calls.live_grep + 1
		end,
	}
	local telescope_helpers = require("revaz.telescope")
	telescope_helpers.find_files()
	telescope_helpers.live_grep()
	package.loaded["telescope.builtin"] = original_builtin
	assert_equal(telescope_calls.find_files, 1, "Telescope find fallback invocation")
	assert_equal(telescope_calls.live_grep, 0, "Telescope live grep skipped without ripgrep")

	local copilot_spec = dofile(config_root .. "/lua/revaz/plugins/copilot.lua")[1]
	assert_equal(copilot_spec.cond(), false, "Copilot disabled without Node")
	local telescope_spec = dofile(config_root .. "/lua/revaz/plugins/telescope.lua")
	assert_equal(telescope_spec.dependencies[2].cond(), false, "fzf-native disabled without build tools")

	vim.g.revaz_preflight_overrides = {
		executables = { curl = true, wget = false, tar = true, unzip = false, gzip = true },
	}
	local original_smoke = vim.env.DOTFILES_NVIM_SMOKE
	local original_mason = package.loaded["mason"]
	local original_mason_lspconfig = package.loaded["mason-lspconfig"]
	local original_mason_null_ls = package.loaded["mason-null-ls"]
	local mason_lsp_opts
	local mason_null_ls_opts
	vim.env.DOTFILES_NVIM_SMOKE = "0"
	package.loaded["mason"] = { setup = function() end }
	package.loaded["mason-lspconfig"] = {
		setup = function(opts)
			mason_lsp_opts = opts
		end,
	}
	package.loaded["mason-null-ls"] = {
		setup = function(opts)
			mason_null_ls_opts = opts
		end,
	}
	local mason_spec = dofile(config_root .. "/lua/revaz/plugins/mason.lua")
	assert_equal(mason_spec.build, ":MasonUpdate", "Mason registry update remains available")
	mason_spec.config()
	if #mason_lsp_opts.ensure_installed == 0 or #mason_null_ls_opts.ensure_installed == 0 then
		fail("missing one archive utility broadly disabled automatic Mason installation")
	end
	package.loaded["mason"] = original_mason
	package.loaded["mason-lspconfig"] = original_mason_lspconfig
	package.loaded["mason-null-ls"] = original_mason_null_ls
	vim.env.DOTFILES_NVIM_SMOKE = original_smoke
	vim.g.revaz_preflight_overrides = { executables = missing_executables }

	vim.notify = original_notify
	vim.cmd("ConfigHealth")
	local completed = vim.wait(30000, function()
		local report = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
		return report:find("Required bootstrap/runtime tools", 1, true) ~= nil
			and report:find("Optional feature tools", 1, true) ~= nil
	end, 100)
	if not completed then
		fail(":ConfigHealth did not complete under injected missing dependencies")
	end
	local report = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
	for _, expected in ipairs({ "Neovim", "git", "tree-sitter CLI", "ripgrep", "Node.js", "impact:" }) do
		if not report:find(expected, 1, true) then
			fail(":ConfigHealth omitted expected dependency information: " .. expected)
		end
	end
	vim.cmd("silent! bwipeout!")

	vim.g.revaz_preflight_overrides = original_overrides
end

local function assert_health()
	vim.cmd("checkhealth lazy nvim-treesitter revaz")
	local completed = vim.wait(30000, function()
		local report = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
		return report ~= "" and not report:find("Running healthchecks", 1, true)
	end, 100)
	if not completed then
		fail("Neovim health checks did not finish within 30 seconds")
	end

	local report = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
	if report:find("%f[%a]ERROR%f[%A]") then
		fail("Neovim health checks reported errors:\n" .. report)
	end
end

local ok, result = xpcall(function()
	if startup_error ~= "" then
		fail("Neovim reported an error while loading init.lua:\n" .. startup_error)
	end
	if vim.fn.has("nvim-0.12") ~= 1 then
		fail("Neovim 0.12 or newer is required")
	end
	if vim.env.DOTFILES_NVIM_SMOKE ~= "1" then
		fail("smoke-test environment was not enabled")
	end

	local source = vim.env.DOTFILES_NVIM_SOURCE
	if not source or vim.fn.isdirectory(source) ~= 1 then
		fail("DOTFILES_NVIM_SOURCE does not identify config/nvim")
	end
	assert_equal(
		read_file(vim.fn.stdpath("config") .. "/init.lua"),
		read_file(source .. "/init.lua"),
		"staged init.lua"
	)

	local plugin_count = assert_locked_plugins()
	assert_lsp_inventory()
	assert_formatting_ownership()
	assert_bigfile_mode()
	assert_preflight(source)
	assert_health()
	return plugin_count
end, debug.traceback)

if not ok then
	vim.api.nvim_err_writeln("Neovim smoke test failed:\n" .. result)
	vim.cmd("cquit 1")
else
	print(("Neovim smoke tests passed (%d locked plugins verified)"):format(result))
	vim.cmd("qa!")
end
