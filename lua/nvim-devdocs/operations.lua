local M = {}

local path = require("plenary.path")

local utils = require("nvim-devdocs.utils")
local plugin_config = require("nvim-devdocs.config").get()

local devdocs_cdn_url = "https://documents.devdocs.io"
local docs_dir = path:new(plugin_config.dir_path, "docs")

M.install = function(entry)
  local alias = entry.slug:gsub("~", "-")
  local file_path = path:new(docs_dir, alias .. ".json")

  if not docs_dir:exists() then docs_dir:mkdir() end

  if file_path:exists() then
    utils.log("Documentation for " .. alias .. " is already installed")
  else
    utils.log("Installing " .. alias .. " documentation...")

    local url = string.format("%s/%s/db.json?%s", devdocs_cdn_url, entry.slug, entry.mtime)
    utils.fetch_async(url, function(res)
      file_path:write(res, "w", 438)
      utils.log("Documentation for " .. alias .. " has been installed")
    end)
  end
end

M.uninstall = function(entry)
  local file_path = path:new(docs_dir, entry .. ".json")

  if not file_path:exists() then
    utils.log(entry .. " documentation is already uninstalled")
  else
    file_path:rm()
    utils.log(entry .. " documentation has been uninstalled")
  end
end

return M
