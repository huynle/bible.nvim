local config = require("bible.config")
local utils = require("bible.utils")
local Lookup = require("bible.lookup")
local M = {}

M.setup = function(options)
	config.setup(options)
end

M.bibleLookup = function(opts)
	opts = opts or {}
	local lookup = Lookup.new(opts)
	local _query = opts.query or vim.fn.input("query: ")
	lookup:fetch_verse({
		query = not utils.isempty(_query) and _query or nil,
	})
end

M.bibleLookupSelection = function(opts)
	opts = opts or {}
	local lookup = Lookup.new(opts)
	local _queries = lookup:get_visual_selection()
	for _, query in ipairs(_queries) do
		lookup:fetch_verse({
			query = query,
		})
	end
end

return M
