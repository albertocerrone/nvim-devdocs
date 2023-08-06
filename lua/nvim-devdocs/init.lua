local M = {}

local path = require("plenary.path")
local utils = require("nvim-devdocs.utils")
local pickers = require("nvim-devdocs.pickers")

local devdocs_site_url = "https://devdocs.io"
local devdocs_cdn_url = "https://documents.devdocs.io"

M.config = {
  dir_path = vim.fn.expand("$HOME/.local/share/nvim/devdocs"),
}

M.get_available_docs = function()
  print("Fetching Devdocs registery...")

  utils.fetch_async(devdocs_site_url .. "/docs.json", function(res)
    local dir_path = path:new(M.config.dir_path)

    if not dir_path:exists() then dir_path:mkdir() end

    local file_path = path:new(M.config.dir_path, "registery.json")
    file_path:write(res, "w", 438)
    print("Devdocs registery has been successfully written to the disk")
  end)
end

M.install = function(args)
  local registery_path = path:new(M.config.dir_path, "registery.json")

  if not registery_path:exists() then
    utils.log_err("Devdocs registery not found, please run :DevdocsFetch")
    return
  end

  local docs_dir = path:new(M.config.dir_path, "docs")

  if not docs_dir:exists() then docs_dir:mkdir() end

  local content = registery_path:read()
  local parsed = vim.fn.json_decode(content)

  if vim.tbl_isempty(args.fargs) then
    pickers.install_picker()
  end

  for _, arg in pairs(args.fargs) do
    local slug = string.gsub(arg, "-", "~")
    local data = {}

    for _, entry in pairs(parsed) do
      if entry.slug == slug then
        data = entry
        break
      end
    end

    if vim.tbl_isempty(data) then
      print("No documentation available for " .. arg)
    else
      local file_path = path:new(docs_dir, arg .. ".json")

      if file_path:exists() then
        print("Documentation for " .. arg .. " is already installed")
      else
        print("Installing documentation for " .. arg)

        local url = string.format("%s/%s/db.json?%s", devdocs_cdn_url, slug, data.mtime)
        utils.fetch_async(url, function(res)
          file_path:write(res, "w", 438)
          print("Documentation for " .. arg .. " has been installed")
        end)
      end
    end
  end
end

return M
