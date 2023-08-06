local M = {}

local config = {
  dir_path = vim.fn.expand("$HOME/.local/share/nvim/devdocs"),
  telescope = {},
}

M.get = function() return config end

M.setup = function(new_config)
  if new_config ~= nil then
    for key, value in pairs(new_config) do
      config[key] = value
    end
  end

  return config
end

return M
