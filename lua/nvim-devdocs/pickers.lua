local M = {}

local path = require("plenary.path")
local actions = require("telescope.actions")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
-- local config = require("nvim-devdocs").config

M.install_picker = function()
  local opts = {}
  local content = path:new(config.dir_path, "registery.json"):read()
  local parsed = vim.fn.json_decode(content)
  local entries = vim.tbl_map(function(entry) return entry.slug end, parsed)

  pickers.new(opts, {
    promp_title = "Install documentation",
    finder = finders.new_table({
      results = entries,
    }),
  })
end

return M
