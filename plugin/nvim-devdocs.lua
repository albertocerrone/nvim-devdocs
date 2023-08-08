local M = require("nvim-devdocs")

M.setup = function(opts)
  local config = require("nvim-devdocs.config")
  local completion = require("nvim-devdocs.completion")
  local operations = require("nvim-devdocs.operations")

  config.setup(opts)

  local ensure_installed = config.get().ensure_installed

  vim.schedule(function() operations.install_args(ensure_installed) end)

  local cmd = vim.api.nvim_create_user_command

  cmd("DevdocsFetch", M.get_available_docs, {})
  cmd("DevdocsInstall", M.install_doc, { nargs = "*", complete = completion.get_all })
  cmd("DevdocsUninstall", M.uninstall_doc, { nargs = "*", complete = completion.get_installed })
  cmd("DevdocsOpen", M.open_doc, { nargs = "?", complete = completion.get_installed })
end

return M
