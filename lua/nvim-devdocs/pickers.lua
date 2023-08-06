local M = {}

local path = require("plenary.path")
local actions = require("telescope.actions")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local config = require("telescope.config").values
local plugin_config = require("nvim-devdocs.config").get()

M.installation_picker = function()
  local opts = {}
  local content = path:new(plugin_config.dir_path, "registery.json"):read()
  local parsed = vim.fn.json_decode(content)
  local entries = vim.tbl_map(function(entry) return string.gsub(entry.slug, "~", "-") end, parsed)

  pickers
    .new(opts, {
      promp_title = "Install documentation",
      finder = finders.new_table({
        results = entries,
      }),
      sorter = config.generic_sorter(opts),
      attach_mappings = function()
        -- TODO: selesction handling
        return true
      end,
    })
    :find()
end

return M
