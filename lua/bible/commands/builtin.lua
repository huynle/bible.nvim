local config = require("bible.config")
local picker = require("bible.pickers."..config.options.picker)
local commands = require("bible.commands")
local actions = require("bible.actions")
local util = require("bible.util")


commands.add("BibleLookupSelection", function(options)
  local selected_text = util.get_text_in_range(util.get_selected_range())
  assert(selected_text ~= nil, "No selected text")
  local options = vim.tbl_extend("force", { query = selected_text }, options or {})
  picker:lookup_verse(options, actions.display_verse)
end, { needs_selection = true})

commands.add("BibleLookupWORD", function(options)
  local selected_text = vim.call('expand','<cWORD>') 
  local options = vim.tbl_extend("force", { query = selected_text }, options or {})
  picker:lookup_verse(options, actions.display_verse)
end)

commands.add("BibleLookup", function(options)
  picker:lookup_verse(options, actions.display_verse)
end)
