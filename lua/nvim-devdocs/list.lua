local M = {}

local path = require("plenary.path")
local scandir = require("plenary.scandir")
local plugin_config = require("nvim-devdocs.config").get()

local docs_dir = path:new(plugin_config.dir_path, "docs")

M.get_installed = function()
  if not docs_dir:exists() then return {} end

  local files = scandir.scan_dir(path.__tostring(docs_dir), { all_dirs = false })
  local installed = vim.tbl_map(function(file_path)
    local splited = path._split(path:new(file_path))
    local filename = splited[#splited]
    local basename = filename:gsub(".json", "")
    return basename
  end, files)

  return installed
end

M.get_installed_entry = function()
  -- TODO
end

return M
