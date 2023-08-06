local M = {}

local Job = require("plenary.job")

M.fetch_async = function(url, callback)
  Job:new({
    command = "curl",
    args = { "-L", "-f", "-s", url },
    on_exit = function(job, code)
      assert(code == 0, string.format("GET %s failed", url))
      callback(job:result())
    end,
  }):start()
end

M.format_entry = function(entry)
  local lines = {}

  local subs = {
    ["&copy;"] = "©",
    ["&ndash;"] = "–",
    ["&lt;"] = "<",
    ["<a.*>(.*)</a>"] = "%1",
    ["<br>"] = "",
    ["\n *"] = " ",
  }

  for key, value in pairs(entry) do
    if key == "attribution" then
      for pattern, repl in pairs(subs) do
        value = string.gsub(value, pattern, repl)
      end
    end

    if key == "links" then value = vim.fn.json_encode(value) end

    table.insert(lines, key .. ": " .. value)
  end

  return lines
end

M.log = function(message) vim.notify(message, vim.log.levels.INFO) end

M.log_warn = function(message) vim.notify(message, vim.log.levels.WARN) end

M.log_err = function(message) vim.notify(message, vim.log.levels.ERROR) end

return M
