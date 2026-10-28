local M = {}

local function run(picker, feature, dependency)
	local preflight = require("revaz.preflight")
	if feature and not preflight.feature_available(feature) then
		preflight.notify_missing(dependency, ("Telescope %s unavailable"):format(picker))
		return
	end
	require("telescope.builtin")[picker]()
end

function M.find_files()
	run("find_files", "telescope_files", "telescope-find")
end

function M.live_grep()
	run("live_grep", "telescope_grep", "telescope-rg")
end

function M.grep_string()
	run("grep_string", "telescope_grep", "telescope-rg")
end

return M
