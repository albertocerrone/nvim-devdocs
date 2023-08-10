local M = {}

local path = require("plenary.path")
local curl = require("plenary.curl")

local notify = require("nvim-devdocs.notify")
local pickers = require("nvim-devdocs.pickers")
local operations = require("nvim-devdocs.operations")
local plugin_config = require("nvim-devdocs.config").get()

local devdocs_site_url = "https://devdocs.io"

M.fetch_registery = function()
  notify.log("Fetching Devdocs registery...")
  curl.get(devdocs_site_url .. "/docs.json", {
    callback = function(response)
      local dir_path = path:new(plugin_config.dir_path)
      local file_path = path:new(plugin_config.dir_path, "registery.json")

      if not dir_path:exists() then dir_path:mkdir() end

      file_path:write(response.body, "w", 438)
      notify.log("Devdocs registery has been successfully written to the disk")
    end,
    on_error = function(error)
      notify.log_err("nvim-devdocs: Error when fetching registery, exit code: " .. error.exit)
    end,
  })
end

M.install_doc = function(args)
  local registery_path = path:new(plugin_config.dir_path, "registery.json")

  if registery_path:exists() then
    if vim.tbl_isempty(args.fargs) then pickers.installation_picker() end

    operations.install_args(args.fargs, true)
  else
    notify.log_err("Devdocs registery not found, please run :DevdocsFetch")
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

return M
