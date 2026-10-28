local M = {}

M.minimum_version = { 0, 12, 0 }
M.version_probe_timeout_ms = 2000

M.none_ls_tools = {
	{ mason = "ansiblelint", executable = "ansible-lint", impact = "none-ls Ansible diagnostics" },
	{ mason = "djlint", executable = "djlint", impact = "none-ls HTML template diagnostics" },
	{ mason = "dotenv_linter", executable = "dotenv-linter", impact = "none-ls dotenv diagnostics" },
	{
		mason = "editorconfig_checker",
		executable = "editorconfig-checker",
		impact = "none-ls EditorConfig diagnostics",
	},
	{ mason = "prettier", executable = "prettier", impact = "none-ls web, YAML, and Markdown formatting" },
	{ mason = "ruff", executable = "ruff", impact = "Python LSP and none-ls formatting" },
	{ mason = "stylua", executable = "stylua", impact = "none-ls Lua formatting" },
}

local notified = {}
local version_cache = {}

local function overrides()
	local value = vim.g.revaz_preflight_overrides
	return type(value) == "table" and value or {}
end

function M.version()
	local override = overrides().version
	if type(override) == "table" then
		return {
			major = tonumber(override.major or override[1]) or 0,
			minor = tonumber(override.minor or override[2]) or 0,
			patch = tonumber(override.patch or override[3]) or 0,
		}
	end

	local version = vim.version()
	return { major = version.major, minor = version.minor, patch = version.patch }
end

function M.version_string(version)
	version = version or M.version()
	return ("%d.%d.%d"):format(version.major, version.minor, version.patch)
end

function M.meets_minimum(version)
	version = version or M.version()
	local minimum = M.minimum_version
	if version.major ~= minimum[1] then
		return version.major > minimum[1]
	end
	if version.minor ~= minimum[2] then
		return version.minor > minimum[2]
	end
	return version.patch >= minimum[3]
end

function M.guard()
	if M.meets_minimum() then
		return true
	end

	vim.api.nvim_err_writeln(
		("This configuration requires Neovim 0.12.0 or newer (found %s). Upgrade Neovim, then restart; configuration loading was stopped."):format(
			M.version_string()
		)
	)
	return false
end

function M.executable(command)
	local executable_overrides = overrides().executables
	if type(executable_overrides) == "table" and executable_overrides[command] ~= nil then
		return executable_overrides[command] == true or executable_overrides[command] == 1
	end
	return vim.fn.executable(command) == 1
end

local function environment(name)
	local environment_overrides = overrides().environment
	if type(environment_overrides) == "table" and environment_overrides[name] ~= nil then
		local value = environment_overrides[name]
		return type(value) == "string" and value ~= "" and value or nil
	end
	local value = vim.env[name]
	return value ~= vim.NIL and value ~= "" and value or nil
end

local compiler_wrappers = {
	ccache = true,
	distcc = true,
	sccache = true,
	xcrun = true,
}

local function command_basename(command)
	return command:match("([^/\\]+)$") or command
end

local function is_direct_compiler(command, allow_msvc)
	local name = command_basename(command)
	return name == "cc"
		or name == "clang"
		or name == "gcc"
		or (allow_msvc and (name == "cl" or name == "clang-cl"))
		or name:match("^.+%-clang[%d%.%-]*$") ~= nil
		or name:match("^.+%-gcc[%d%.%-]*$") ~= nil
end

local function compiler_commands(default, use_environment, allow_msvc)
	local value = use_environment == false and nil or environment("CC")
	if not value then
		return { default }
	end
	if value:find("[\"'`$|&;<>()]") then
		return nil, ("an executable CC command without shell syntax (found %q)"):format(value)
	end

	local words = vim.split(vim.trim(value), "%s+", { trimempty = true })
	local first = words[1]
	if not first then
		return nil, "an executable CC command"
	end
	if #words == 1 then
		if is_direct_compiler(first, allow_msvc) then
			return { first }
		end
		return nil, ("a recognized compiler command (found %q)"):format(value)
	end

	local first_name = command_basename(first)
	if compiler_wrappers[first_name] and #words == 2 and is_direct_compiler(words[2], allow_msvc) then
		return words
	end
	if first_name == "zig" and #words == 2 and words[2] == "cc" then
		return { first }
	end

	return nil, ("an unambiguous executable CC command (found %q)"):format(value)
end

local function compiler_requirement(default, use_environment, allow_msvc)
	local commands, error = compiler_commands(default, use_environment, allow_msvc)
	local groups = {}
	for _, command in ipairs(commands or {}) do
		table.insert(groups, { command })
	end
	return groups, error
end

local function command_version(command)
	local version_overrides = overrides().versions
	if type(version_overrides) == "table" and version_overrides[command] ~= nil then
		return tostring(version_overrides[command])
	end
	if version_cache[command] ~= nil then
		return version_cache[command] or nil
	end

	local result = vim.system({ command, "--version" }, { text = true }):wait(M.version_probe_timeout_ms)
	local output = (result.stdout or "") .. (result.stderr or "")
	local version = result.code == 0 and output:match("%d+%.%d+%.%d+") or nil
	version_cache[command] = version or false
	return version
end

local function version_at_least(actual, minimum)
	local actual_parts = { actual:match("^(%d+)%.(%d+)%.(%d+)") }
	for index, required in ipairs(minimum) do
		local found = tonumber(actual_parts[index]) or 0
		if found ~= required then
			return found > required
		end
	end
	return true
end

local function entry(id, category, label, groups, impact, install, probe)
	return {
		id = id,
		category = category,
		label = label,
		groups = groups,
		impact = impact,
		install = install,
		probe = probe,
	}
end

local function static_inventory()
	local treesitter_compilers, treesitter_compiler_error = compiler_requirement("cc", true, true)
	local is_windows = vim.fn.has("win32") == 1
	local fzf_default_compiler = is_windows and "gcc" or "cc"
	local fzf_compilers, fzf_compiler_error = compiler_requirement(fzf_default_compiler, not is_windows, false)
	return {
		entry(
			"lazy-git",
			"required",
			"git",
			{ { "git" } },
			"lazy.nvim bootstrap/plugin updates and Mason packages that use Git",
			"Install Git (macOS/Homebrew: brew install git)."
		),
		entry(
			"treesitter-cli",
			"optional",
			"tree-sitter CLI and parser toolchain",
			vim.list_extend({ { "tree-sitter" }, { "curl" }, { "tar" } }, treesitter_compilers),
			"Tree-sitter parser installation and updates; installed parsers keep working",
			"Install tree-sitter CLI 0.26.1 or newer, curl, tar, and the compiler selected by CC (cc by default) (macOS/Homebrew: brew install tree-sitter-cli curl; xcode-select --install).",
			function()
				if treesitter_compiler_error then
					return false, treesitter_compiler_error
				end
				local version = command_version("tree-sitter")
				if version and version_at_least(version, { 0, 26, 1 }) then
					return true
				end
				return false,
					version and ("tree-sitter CLI 0.26.1 or newer (found " .. version .. ")")
						or "a readable tree-sitter CLI version (0.26.1 or newer)"
			end
		),
		entry(
			"mason-download",
			"optional",
			"Mason downloader (curl or wget)",
			{ { "curl", "wget" } },
			"automatic Mason package downloads",
			"Install curl or wget (macOS/Homebrew: brew install curl)."
		),
		entry(
			"mason-tar",
			"optional",
			"tar",
			{ { "tar", "gtar" } },
			"Mason extraction for tar archives",
			"Install GNU tar (macOS/Homebrew: brew install gnu-tar)."
		),
		entry(
			"mason-unzip",
			"optional",
			"unzip",
			{ { "unzip" } },
			"Mason extraction for zip archives",
			"Install unzip (macOS provides it; otherwise use the system package manager)."
		),
		entry(
			"mason-gzip",
			"optional",
			"gzip",
			{ { "gzip" } },
			"Mason extraction for gzip-compressed packages",
			"Install gzip (macOS provides it; otherwise use the system package manager)."
		),
		entry(
			"telescope-fd",
			"optional",
			"fd",
			{ { "fd", "fdfind" } },
			"fast Telescope file search; find_files falls back to find when available",
			"Install fd (macOS/Homebrew: brew install fd)."
		),
		entry(
			"telescope-find",
			"optional",
			"Telescope file-search backend",
			{ { "fd", "fdfind", "rg", "find", "where" } },
			"Telescope find_files",
			"Install fd or ripgrep, or ensure the platform file-search command is available (macOS/Homebrew: brew install fd)."
		),
		entry(
			"telescope-rg",
			"optional",
			"ripgrep",
			{ { "rg" } },
			"Telescope live_grep and grep_string",
			"Install ripgrep (macOS/Homebrew: brew install ripgrep)."
		),
		entry(
			"fzf-make",
			"optional",
			"make",
			{ { "make" } },
			"building telescope-fzf-native; Telescope uses its Lua sorter without it",
			"Install build tools (macOS: xcode-select --install, or Homebrew: brew install make)."
		),
		entry(
			"fzf-compiler",
			"optional",
			"C compiler used by make",
			fzf_compilers,
			"building telescope-fzf-native; Telescope uses its Lua sorter without it",
			"Install a cc-compatible compiler, or set CC to an available compiler command (macOS: xcode-select --install).",
			function()
				return fzf_compiler_error == nil, fzf_compiler_error
			end
		),
		entry(
			"copilot-node",
			"optional",
			"Node.js",
			{ { "node" } },
			"GitHub Copilot",
			"Install a supported Node.js release (macOS/Homebrew: brew install node)."
		),
		entry(
			"python-provider",
			"optional",
			"Python 3 provider",
			{ { "python3", "python" } },
			"Neovim Python-provider plugins; core editing and Python LSP remain available",
			"Install Python 3 and pynvim in the environment Neovim discovers (macOS/Homebrew: brew install python; python3 -m pip install --user pynvim).",
			function()
				return vim.fn.has("python3") == 1, "pynvim in a discoverable Python environment"
			end
		),
	}
end

function M.inventory()
	local inventory = static_inventory()
	local servers = require("revaz.lsp.servers")
	for _, name in ipairs(servers.names()) do
		local server = servers.servers[name]
		local groups = { { server.cmd[1] } }
		for _, command in ipairs(server.system_dependencies or {}) do
			table.insert(groups, { command })
		end
		table.insert(
			inventory,
			entry(
				"lsp-" .. name,
				"optional",
				name .. " LSP",
				groups,
				name .. " language features for its configured filetypes",
				("Run :Mason and install %s; also install any project/system runtime it reports."):format(name)
			)
		)
	end

	for _, tool in ipairs(M.none_ls_tools) do
		table.insert(
			inventory,
			entry(
				"none-ls-" .. tool.mason,
				"optional",
				tool.executable,
				{ { tool.executable } },
				tool.impact,
				("Run :Mason and install %s, or install %s with its normal package manager."):format(
					tool.mason,
					tool.executable
				)
			)
		)
	end

	return inventory
end

function M.status(item)
	local missing = {}
	for _, alternatives in ipairs(item.groups) do
		local found = false
		for _, command in ipairs(alternatives) do
			if M.executable(command) then
				found = true
				break
			end
		end
		if not found then
			table.insert(missing, table.concat(alternatives, " or "))
		end
	end
	if #missing == 0 and item.probe then
		local ok, requirement = item.probe()
		if not ok then
			table.insert(missing, requirement)
		end
	end
	return #missing == 0, missing
end

function M.find(id)
	for _, item in ipairs(M.inventory()) do
		if item.id == id then
			return item
		end
	end
end

function M.available(id)
	local item = M.find(id)
	return item ~= nil and M.status(item)
end

function M.feature_available(feature)
	if feature == "fzf-native" then
		return M.available("fzf-make") and M.available("fzf-compiler")
	end
	local features = {
		lazy = "lazy-git",
		treesitter = "treesitter-cli",
		telescope_files = "telescope-find",
		telescope_grep = "telescope-rg",
		copilot = "copilot-node",
	}
	return M.available(features[feature])
end

function M.notify_missing(id, prefix)
	if notified[id] then
		return
	end
	local item = M.find(id)
	if not item then
		return
	end
	local ok, missing = M.status(item)
	if ok then
		return
	end
	notified[id] = true
	vim.notify(
		("%sMissing %s (%s). Impact: %s. %s"):format(
			prefix and (prefix .. ": ") or "",
			table.concat(missing, ", "),
			item.label,
			item.impact,
			item.install
		),
		item.category == "required" and vim.log.levels.ERROR or vim.log.levels.WARN
	)
end

function M.notify_feature(feature, prefix)
	local notification_id = "feature:" .. feature
	if notified[notification_id] then
		return
	end
	local ids = {
		["fzf-native"] = { "fzf-make", "fzf-compiler" },
	}
	local missing = {}
	for _, id in ipairs(ids[feature] or {}) do
		local item = M.find(id)
		local ok, item_missing = M.status(item)
		if not ok then
			vim.list_extend(missing, item_missing)
		end
	end
	if #missing == 0 then
		return
	end
	notified[notification_id] = true
	vim.notify(
		("%s: missing %s. Run :ConfigHealth for feature impact and installation guidance."):format(
			prefix,
			table.concat(missing, ", ")
		),
		vim.log.levels.WARN
	)
end

function M.none_ls_mason_names()
	local names = {}
	for _, tool in ipairs(M.none_ls_tools) do
		table.insert(names, tool.mason)
	end
	return names
end

function M.setup()
	vim.api.nvim_create_user_command("ConfigHealth", function()
		vim.cmd("checkhealth revaz")
	end, { desc = "Check this Neovim configuration's external dependencies" })
end

return M
