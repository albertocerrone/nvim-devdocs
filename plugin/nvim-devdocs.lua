local M = require("nvim-devdocs")

M.setup = function(opts)
  local config = require("nvim-devdocs.config")
  local completion = require("nvim-devdocs.completion")

  config.setup(opts)

  local cmd = vim.api.nvim_create_user_command

  cmd("DevdocsFetch", M.get_available_docs, {})
  cmd("DevdocsInstall", M.install_doc, { nargs = "*", complete = completion.get_all })
  cmd("DevdocsUninstall", M.uninstall_doc, { nargs = "*", complete = completion.get_installed })
end

return M
