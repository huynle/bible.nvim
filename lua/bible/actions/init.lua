local ui = require("bible.ui")

local M = {}

-- display the verse in an ephemeral window 
function M.display_verse(verse, options)
  local ui_options = {
    test="Testing"
  }
  ui.ephemeral_entry(verse, options or ui_options)
end

-- insert verse into the current location
function M.insert_verse(verse, options)
  local ui_options = {
    test="Testing"
  }
  ui.ephemeral_entry(verse, options or ui_options)
end

return M
