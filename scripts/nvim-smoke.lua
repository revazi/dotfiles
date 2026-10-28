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

local function assert_markdown_treesitter()
	local install = require("nvim-treesitter").install({ "markdown", "markdown_inline" })
	install:wait(120000)

	local state_dir = vim.fn.stdpath("state") .. "/smoke"
	vim.fn.mkdir(state_dir, "p")
	local small_path = state_dir .. "/small.md"
	local large_path = state_dir .. "/large.md"
	vim.fn.writefile({ "# Small Markdown", "", "Treesitter should parse *this* file." }, small_path)
	vim.fn.writefile({ string.rep("Large Markdown content.\n", 12000) }, large_path)

	vim.cmd.edit(vim.fn.fnameescape(small_path))
	local small_buf = vim.api.nvim_get_current_buf()
	assert_equal(vim.bo[small_buf].filetype, "markdown", "small fixture filetype")
	if not vim.wait(5000, function()
		return vim.treesitter.highlighter.active[small_buf] ~= nil
	end, 50) then
		fail("Treesitter did not activate for a small Markdown file")
	end

	vim.cmd.edit(vim.fn.fnameescape(large_path))
	local large_buf = vim.api.nvim_get_current_buf()
	assert_equal(vim.bo[large_buf].filetype, "markdown", "large fixture filetype")
	if vim.treesitter.highlighter.active[large_buf] ~= nil then
		fail("Treesitter remained active for Markdown larger than 200 KiB")
	end
end

local function assert_health()
	vim.cmd("checkhealth lazy nvim-treesitter")
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
	assert_markdown_treesitter()
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
