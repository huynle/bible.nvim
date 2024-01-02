local view_og = require("bible.view_og")
local View = require("bible.view")

local M = {}

M.defaults = {}
M.options = M.defaults -- not necessary, but better code completion

-- display the text in an ephemeral window
function M.display_text(lines, options)
  local options = vim.tbl_extend("force", M.options, options)
  view_og.ephemeral_entry(lines, options)
end

-- display the text in an ephemeral window
function M.display_text_new(lines, options)
  local options = vim.tbl_extend("force", M.options, options)
  -- dump(options)
  local view = View.create(options)
  -- dump(view)
  -- view_og.ephemeral_entry(lines, options)
end

-- insert text into the current location
function M.insert_text(text, options)
  local options = vim.tbl_extend("force", M.options, options)
  view_og.ephemeral_entry(text, options or ui_options)
end

return M
