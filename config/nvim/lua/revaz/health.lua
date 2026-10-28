local M = {}

function M.check()
	local health = vim.health
	local preflight = require("revaz.preflight")
	local version = preflight.version()

	health.start("Neovim configuration")
	if preflight.meets_minimum(version) then
		health.ok(("Neovim %s (minimum 0.12.0)"):format(preflight.version_string(version)))
	else
		health.error(
			("Neovim %s is unsupported; install Neovim 0.12.0 or newer."):format(preflight.version_string(version))
		)
	end

	for _, category in ipairs({ "required", "optional" }) do
		health.start(category == "required" and "Required bootstrap/runtime tools" or "Optional feature tools")
		for _, item in ipairs(preflight.inventory()) do
			if item.category == category then
				local ok, missing = preflight.status(item)
				if ok then
					health.ok(("%s: available — %s"):format(item.label, item.impact))
				else
					local message = ("%s: missing %s — impact: %s. %s"):format(
						item.label,
						table.concat(missing, ", "),
						item.impact,
						item.install
					)
					if category == "required" then
						health.error(message)
					else
						health.warn(message)
					end
				end
			end
		end
	end
end

return M
