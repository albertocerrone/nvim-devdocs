local nvim_devdocs = require("nvim-devdocs")
local completion = require("nvim-devdocs.completion")

local cmd = vim.api.nvim_create_user_command

cmd("DevdocsFetch", nvim_devdocs.get_available_docs, {})
cmd("DevdocsInstall", nvim_devdocs.install, { nargs = "*", complete = completion.get_all })

return nvim_devdocs
