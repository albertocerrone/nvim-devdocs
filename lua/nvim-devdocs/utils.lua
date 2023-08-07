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

M.log = function(message) vim.notify(message, vim.log.levels.INFO) end

M.log_warn = function(message) vim.notify(message, vim.log.levels.WARN) end

M.log_err = function(message) vim.notify(message, vim.log.levels.ERROR) end

return M
