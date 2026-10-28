-- Register large-file detection before lazy.nvim creates plugin event handlers.
require("revaz.bigfile").setup()
require("revaz.plugins-setup")
require("revaz.core.options")
require("revaz.core.filetypes")
require("revaz.core.keymaps")
