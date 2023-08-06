local M = {}

local path = require("plenary.path")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local previewers = require("telescope.previewers")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local config = require("telescope.config").values
local operations = require("nvim-devdocs.operations")

local plugin_config = require("nvim-devdocs.config").get()
local utils = require("nvim-devdocs.utils")

local telescope_opts = plugin_config.telescope

M.installation_picker = function()
  local content = path:new(plugin_config.dir_path, "registery.json"):read()
  local parsed = vim.fn.json_decode(content)

  pickers
    .new(telescope_opts, {
      prompt_title = "Install documentation",
      finder = finders.new_table({
        results = parsed,
        entry_maker = function(entry)
          return {
            value = entry,
            display = entry.slug:gsub("~", "-"),
            ordinal = entry.slug:gsub("~", "-"),
          }
        end,
      }),
      sorter = config.generic_sorter(telescope_opts),
      previewer = previewers.new_buffer_previewer({
        title = "Metadata",
        define_preview = function(self, entry)
          local bufnr = self.state.bufnr
          local lines = utils.format_entry(entry.value)
          vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
          vim.bo[bufnr].ft = "yaml"
        end,
      }),
      attach_mappings = function()
        actions.select_default:replace(function(prompt_bufnr)
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          operations.install(selection.value)
        end)
        return true
      end,
    })
    :find()
end

M.uninstallation_picker = function()
  -- TODO
end

return M
