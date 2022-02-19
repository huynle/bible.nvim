local config = require("bible.config")
local scraper = require("bible.scrapers."..config.options.scraper)
local commands = require("bible.commands")
local actions = require("bible.actions")
local util = require("bible.util")


commands.add("BibleLookupSelection", function(options)
  local selected_text = util.get_text_in_range(util.get_selected_range())
  assert(selected_text ~= nil, "No selected text")
  local options = vim.tbl_extend("force", { query = selected_text }, options or {})
  scraper:lookup_verse(actions.display_verse, options)
end, { needs_selection = true})

commands.add("BibleLookupWORD", function(options)
  local selected_text = vim.call('expand','<cWORD>') 
  local options = vim.tbl_extend("force", { query = selected_text }, options or {})
  scraper:lookup_verse(actions.display_verse, options)
end)

commands.add("BibleLookup", function(options)
  scraper:lookup_verse(actions.display_verse, options)
end)
