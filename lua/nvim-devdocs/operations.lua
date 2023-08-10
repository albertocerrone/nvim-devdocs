local M = {}

local path = require("plenary.path")

local utils = require("nvim-devdocs.utils")
local transpiler = require("nvim-devdocs.transpiler")
local plugin_config = require("nvim-devdocs.config").get()

local devdocs_cdn_url = "https://documents.devdocs.io"
local docs_dir = path:new(plugin_config.dir_path, "docs")
local registery_path = path:new(plugin_config.dir_path, "registery.json")

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

M.install_args = function(args)
  local content = registery_path:read()
  local parsed = vim.fn.json_decode(content)

  for _, arg in ipairs(args) do
    local slug = arg:gsub("-", "~")
    local data = {}

    for _, entry in ipairs(parsed) do
      if entry.slug == slug then
        data = entry
        break
      end
    end

    if vim.tbl_isempty(data) then
      utils.log_err("No documentation available for " .. arg)
    else
      M.install(data)
    end
  end
end

M.uninstall = function(alias)
  local file_path = path:new(docs_dir, alias .. ".json")

  if not file_path:exists() then
    utils.log(alias .. " documentation is already uninstalled")
  else
    file_path:rm()
    utils.log(alias .. " documentation has been uninstalled")
  end
end

M.get_entries = function(arg)
  local file_path = path:new(plugin_config.dir_path, "docs", arg .. ".json")

  if not file_path:exists() then
    utils.log_err(arg .. " documentation is not installed")
    return
  end

  local entries = {}
  local content = file_path:read()
  local decoded = vim.fn.json_decode(content)

  for key, value in pairs(decoded) do
    table.insert(entries, { key = key, value = value })
  end

  return entries
end

M.open = function(entry, float)
  local markdown = transpiler.html_to_md(entry.value)
  local lines = vim.split(markdown, "\n")
  local buf = vim.api.nvim_create_buf(not float, true)

  vim.bo[buf].ft = "markdown"
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)

  if not float then
    vim.api.nvim_set_current_buf(buf)
  else
    local ui = vim.api.nvim_list_uis()[1]
    local row = (ui.height - plugin_config.float_win.height) * 0.5
    local col = (ui.width - plugin_config.float_win.width) * 0.5
    local float_opts = plugin_config.float_win

    if not plugin_config.row then float_opts.row = row end
    if not plugin_config.col then float_opts.col = col end

    local win = vim.api.nvim_open_win(buf, true, float_opts)

    vim.wo[win].wrap = plugin_config.wrap
    vim.wo[win].nu = false
    vim.wo[win].relativenumber = false
  end
end

return M
