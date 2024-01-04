local config = require("bible.config")
local providers = require("bible.providers")
local Lookup = require("bible.lookup")
local M = {}

M.setup = function(options)
	config.setup(options)
	providers.setup(config.options.providers)
end

M.bibleLookup = function(opts)
	local lookup = Lookup.new(opts)
	lookup:fetchVerse({
		query = vim.fn.input("verse: "),
	})
end

M.bibleLookupSelection = function(opts)
	local lookup = Lookup.new(opts)
	lookup:fetchVerseFromSelection()
end

return M
