local config = require("bible.config")

local M = {}

M.folded = {}

function M.is_folded(name)
  local fold = M.folded[name]
  return (fold == nil and config.options.auto_fold == true) or (fold == true)
end

function M.toggle(name)
  M.folded[name] = not M.is_folded(name)
end

function M.close(name)
  M.folded[name] = true
end

function M.open(name)
  M.folded[name] = false
end

return M
