local preflight = require("revaz.preflight")
if not preflight.guard() then
	return
end
preflight.setup()

-- Register large-file detection before lazy.nvim creates plugin event handlers.
require("revaz.bigfile").setup()
if not require("revaz.plugins-setup") then
	return
end
require("revaz.core.options")
require("revaz.core.filetypes")
require("revaz.core.keymaps")
