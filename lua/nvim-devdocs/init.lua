local M = {}

local path = require("plenary.path")

local notify = require("nvim-devdocs.notify")
local pickers = require("nvim-devdocs.pickers")
local operations = require("nvim-devdocs.operations")
local plugin_config = require("nvim-devdocs.config").get()

M.fetch_registery = function() operations.fetch(true) end

M.install_doc = function(args)
  local registery_path = path:new(plugin_config.dir_path, "registery.json")

  if registery_path:exists() then
    if vim.tbl_isempty(args.fargs) then pickers.installation_picker() end

    operations.install_args(args.fargs, true)
  else
    notify.log_err("DevDocs registery not found, please run :DevdocsFetch")
  end
end

M.uninstall_doc = function(args)
  if vim.tbl_isempty(args.fargs) then pickers.uninstallation_picker() end

  for _, arg in pairs(args.fargs) do
    operations.uninstall(arg)
  end
end

-- TODO: Search globally when no args provided

M.open_doc = function(args)
  local arg = args.fargs[1]
  local entries = operations.get_entries(arg)

  if entries then
    pickers.open_doc_entry_picker(entries, false)
  else
    notify.log_err(arg .. " documentation is not installed")
  end
end

M.open_doc_float = function(args)
  local arg = args.fargs[1]
  local entries = operations.get_entries(arg)

  if entries then
    pickers.open_doc_entry_picker(entries, true)
  else
    notify.log_err(arg .. " documentation is not installed")
  end
end

M.check_update = function()
  -- TODO
end

return M
