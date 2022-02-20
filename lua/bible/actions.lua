local view = require("bible.view")

local M = {}

M.defaults = {}
M.options = M.defaults -- not necessary, but better code completion

-- display the verse in an ephemeral window 
function M.display_verse(lines, options)
  local options = vim.tbl_extend("force", M.options, options)
  view.ephemeral_entry(lines, options)
end

-- insert verse into the current location
function M.insert_verse(verse, options)
  local options = vim.tbl_extend("force", M.options, options)
  view.ephemeral_entry(verse, options or ui_options)
end

return M
