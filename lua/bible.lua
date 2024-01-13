local config = require("bible.config")
local utils = require("bible.utils")
local Lookup = require("bible.lookup")
local M = {}

M.setup = function(options)
	config.setup(options)
end

M._do = function(query, opts)
	-- split query by command, if there are any
	local _queries = utils.split_and_join(query, { split = "," }) or {}
	for _, query in ipairs(_queries) do
		-- if version is a table split it up
		if opts.version then
			local versions = opts.version
			if type(opts.version) == "string" then
				versions = utils.split_and_join(opts.version, { split = "," }) or {}
			end

			for _, version in ipairs(versions) do
				-- make sure the individual string in the version is not command separated either
				local _versions = utils.split_and_join(version, { split = "," }) or {}

				for _, _version in ipairs(_versions) do
					local updated_opts = vim.tbl_extend("force", opts, { version = _version })
					M.do_lookup(query, updated_opts)
				end
			end
		else
			M.do_lookup(query, opts)
		end
	end
end

M.do_lookup = function(query, opts)
	local lookup = Lookup.new(opts)
	lookup:fetch_verse({
		query = not utils.isempty(query) and query or nil,
	})
end

M.bibleLookup = function(opts)
	opts = opts or {}
	local _query = opts.query or vim.fn.input("query: ")
	M._do(_query, opts)
end

M.bibleLookupSelection = function(opts)
	opts = opts or {}
	local lookup = Lookup.new(opts)
	local visual_selection = table.concat(lookup:get_visual_selection(), ", ")
	M._do(visual_selection, opts)
end

return M
