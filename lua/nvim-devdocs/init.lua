local M = {}

local path = require("plenary.path")

local utils = require("nvim-devdocs.utils")
local pickers = require("nvim-devdocs.pickers")
local operations = require("nvim-devdocs.operations")
local plugin_config = require("nvim-devdocs.config").get()

local devdocs_site_url = "https://devdocs.io"

M.get_available_docs = function()
  utils.log("Fetching Devdocs registery...")

  utils.fetch_async(devdocs_site_url .. "/docs.json", function(res)
    local dir_path = path:new(plugin_config.dir_path)

    if not dir_path:exists() then dir_path:mkdir() end

    local file_path = path:new(plugin_config.dir_path, "registery.json")
    file_path:write(res, "w", 438)
    utils.log("Devdocs registery has been successfully written to the disk")
  end)
end

M.install_doc = function(args)
  local registery_path = path:new(plugin_config.dir_path, "registery.json")

  if not registery_path:exists() then
    utils.log_err("Devdocs registery not found, please run :DevdocsFetch")
    return
  end

  local content = registery_path:read()
  local parsed = vim.fn.json_decode(content)

  if vim.tbl_isempty(args.fargs) then pickers.installation_picker() end

  for _, arg in pairs(args.fargs) do
    local slug = arg:gsub("-", "~")
    local data = {}

    for _, entry in pairs(parsed) do
      if entry.slug == slug then
        data = entry
        break
      end
    end

    if vim.tbl_isempty(data) then
      utils.log("No documentation available for " .. arg)
    else
      operations.install(data)
    end
  end
end

M.uninstall_doc = function(args)
  for _, arg in pairs(args.fargs) do
    operations.uninstall(arg)
  end
end

return M
