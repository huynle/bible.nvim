local config = require("bible.config")
local utils = require("bible.utils")
local Lookup = require("bible.lookup")
local M = {}

M.setup = function(options)
	config.setup(options)
end

M.bibleLookup = function(opts)
	opts = opts or {}
	local _query = opts.query or vim.fn.input("query: ")
	local _queries = utils.split_and_join(_query, { split = "," }) or {}
	for _, query in ipairs(_queries) do
		local lookup = Lookup.new(opts)
		lookup:fetch_verse({
			query = not utils.isempty(query) and query or nil,
		})
	end
end

M.bibleLookupSelection = function(opts)
	opts = opts or {}
	local lookup = Lookup.new(opts)
	local visual_selection = table.concat(lookup:get_visual_selection(), ", ")
	local _queries = utils.split_and_join(visual_selection, { split = "," }) or {}
	for _, query in ipairs(_queries) do
		local lookup = Lookup.new(opts)
		lookup:fetch_verse({
			query = not utils.isempty(query) and query or nil,
		})
	end
end

return M
