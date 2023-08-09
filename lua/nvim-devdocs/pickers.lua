local M = {}

local path = require("plenary.path")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local previewers = require("telescope.previewers")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local config = require("telescope.config").values

local operations = require("nvim-devdocs.operations")
local list = require("nvim-devdocs.list")
local transpiler = require("nvim-devdocs.transpiler")

local plugin_config = require("nvim-devdocs.config").get()

local telescope_opts = plugin_config.telescope

local new_docs_picker = function(prompt, entries, previwer, attach)
  return pickers.new(telescope_opts, {
    prompt_title = prompt,
    finder = finders.new_table({
      results = entries,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry.slug:gsub("~", "-"),
          ordinal = entry.slug:gsub("~", "-"),
        }
      end,
    }),
    sorter = config.generic_sorter(telescope_opts),
    previewer = previwer,
    attach_mappings = attach,
  })
end

local metadata_priewer = previewers.new_buffer_previewer({
  title = "Metadata",
  define_preview = function(self, entry)
    local bufnr = self.state.bufnr
    local transpiled = transpiler.to_yaml(entry.value)
    local lines = vim.split(transpiled, "\n")
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    vim.bo[bufnr].ft = "yaml"
  end,
})

M.installation_picker = function()
  local content = path:new(plugin_config.dir_path, "registery.json"):read()
  local parsed = vim.fn.json_decode(content)
  local picker = new_docs_picker("Install documentation", parsed, metadata_priewer, function()
    actions.select_default:replace(function(prompt_bufnr)
      actions.close(prompt_bufnr)
      local selection = action_state.get_selected_entry()
      operations.install(selection.value)
    end)
    return true
  end)

  picker:find()
end

M.uninstallation_picker = function()
  local installed = list.get_installed_entry()
  local picker = new_docs_picker("Uninstall documentation", installed, metadata_priewer, function()
    actions.select_default:replace(function(prompt_bufnr)
      actions.close(prompt_bufnr)
      local selection = action_state.get_selected_entry()
      local alias = selection.value.slug:gsub("~", "-")
      operations.uninstall(alias)
    end)
    return true
  end)

  picker:find()
end

M.open_doc_entry_picker = function(entries, float)
  local picker = pickers.new(telescope_opts, {
    prompt_title = "Select an entry",
    finder = finders.new_table({
      results = entries,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry.key,
          ordinal = entry.key,
        }
      end,
    }),
    sorter = config.generic_sorter(telescope_opts),
    previewer = previewers.new_buffer_previewer({
      title = "Preview",
      define_preview = function(self, entry)
        local bufnr = self.state.bufnr
        local markdown = transpiler.html_to_md(entry.value.value)
        local lines = vim.split(markdown, "\n")
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
        vim.bo[bufnr].ft = "markdown"
      end,
    }),
    attach_mappings = function()
      actions.select_default:replace(function(prompt_bufnr)
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        local markdown = transpiler.html_to_md(selection.value.value)
        local lines = vim.split(markdown, "\n")
        local buf = vim.api.nvim_create_buf(not float, true)

        vim.bo[buf].ft = "markdown"
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

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
      end)
      return true
    end,
  })

  picker:find()
end

return M
