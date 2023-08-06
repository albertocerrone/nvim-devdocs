local M = {}

local path = require("plenary.path")
local plugin_config = require("nvim-devdocs.config").get()

M.get_all = function(arg_lead, _, _)
  local registery_path = path:new(plugin_config.dir_path, "registery.json")

  if not registery_path:exists() then return {} end

  local content = registery_path:read()
  local parsed = vim.fn.json_decode(content)
  local args = {}

  for _, entry in pairs(parsed) do
    local arg = string.gsub(entry.slug, "~", "-")
    local starts_with = string.find(arg, arg_lead, 1, true) == 1
    if starts_with then table.insert(args, arg) end
  end

  return args
end

return M
