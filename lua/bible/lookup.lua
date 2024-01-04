local Popup = require("bible.popup")
local Job = require("plenary.job")
local classes = require("bible.common.classes")
local utils = require("bible.utils")

local Lookup = classes.class()

function Lookup:init(opts)
	self.opts = opts or {}
end

function Lookup:get_bufnr()
	if not self._bufnr then
		self._bufnr = vim.api.nvim_get_current_buf()
	end
	return self._bufnr
end

function Lookup:get_visual_selection()
	-- return lines and selection, but caches them, so they always are the ones used
	-- when the action was started, even if the user has changed buffer/selection
	if self._selection then
		return unpack(self._selection)
	end
	local bufnr = self:get_bufnr()
	local lines, start_row, start_col, end_row, end_col = utils.get_visual_lines(bufnr)
	self._selection = { lines, start_row, start_col, end_row, end_col }

	return lines, start_row, start_col, end_row, end_col
end

local function _urlencode(value)
	if type(value) == "table" then
		local _value = {}
		for _, item in ipairs(value) do
			local _encoded = _urlencode(item)
			table.insert(_value, _encoded)
		end
		return table.concat(_value, "%%20")
	else
		return string.gsub(value, " ", "%%20") -- Encode spaces as %20
	end
end

local function urlencode(params)
	local encoded_params = {}
	for key, value in pairs(params) do
		key = _urlencode(key) -- Encode spaces as %20
		value = _urlencode(value) -- Encode spaces as %20
		table.insert(encoded_params, key .. "=" .. value)
	end
	return table.concat(encoded_params, "&")
end

-- local function urlencode(params)
-- 	local encoded_params = {}
-- 	for key, value in pairs(params) do
-- 		if type(value) == "table" then
-- 		end
-- 		key = string.gsub(key, " ", "%%20") -- Encode spaces as %20
-- 		value = string.gsub(value, " ", "%%20") -- Encode spaces as %20
-- 		table.insert(encoded_params, key .. "=" .. value)
-- 	end
-- 	return table.concat(encoded_params, "&")
-- end

function Lookup:form_URL(opts)
	opts = opts or {}
	local defaults = {
		version = "NABRE",
		query = "Genesis 1:1",
	}
	opts = vim.tbl_extend("keep", opts, defaults)

	local uri = "https://www.biblegateway.com/passage/"
	local uris = {}

	if type(opts.query) == "string" then
		local params = {
			interface = "print",
			version = opts.version,
			search = _urlencode(opts.query),
		}
		table.insert(uris, uri .. "?" .. urlencode(params))
	else
		for _, item in ipairs(opts.query) do
			local params = {
				interface = "print",
				version = opts.version,
				search = _urlencode(item),
			}
			table.insert(uris, uri .. "?" .. urlencode(params))
		end
	end

	return uris
end

local function compareVerseKeys(a, b)
	local aBook, aChapter, aVerse = a:match("^(.-)%-(%d+)%-(%d+)$")
	local bBook, bChapter, bVerse = b:match("^(.-)%-(%d+)%-(%d+)$")
	aChapter = tonumber(aChapter)
	bChapter = tonumber(bChapter)
	aVerse = tonumber(aVerse)
	bVerse = tonumber(bVerse)

	if aBook ~= bBook then
		return aBook < bBook
	elseif aChapter ~= bChapter then
		return aChapter < bChapter
	else
		return aVerse < bVerse
	end
end

local function sort_verse(myTable)
	local sortedKeys = {}
	for key, _ in pairs(myTable) do
		table.insert(sortedKeys, key)
	end

	table.sort(sortedKeys, compareVerseKeys) -- Sorts the keys alphabetically
	return sortedKeys
end

function Lookup:fetchVerseFromSelection(opts)
	opts = opts or {}
	opts.query = self:get_visual_selection()
	return self:fetchVerse(opts)
end

function Lookup:fetchVerse(opts)
	-- fetch the bible verse and extract only text
	opts = opts or {}
	local book = {}

	local responses = Lookup:curl(opts)

	for ith, response in ipairs(responses) do
		local job1 = Lookup.get_verse(response, {
			on_exit = function(j, _, _)
				vim.schedule(function()
					local json = vim.fn.json_decode(j:result()) or {}
					local _extracted = Lookup:extract_span_text(json)
					book = vim.tbl_extend("force", book, _extracted)

					Lookup:add_footnote(response, book)
				end)
			end,
		})

		-- local job2 = Bible.get_footnote(response, id, {
		-- 	on_exit = function(j, _, _)
		-- 		vim.schedule(function()
		-- 			local _result = j:result()
		-- 			local json = vim.fn.json_decode(_result) or {}
		-- 			book = vim.tbl_extend("force", book, {})
		-- 		end)
		-- 	end,
		-- })

		job1:after(function(j, code, signal)
			vim.schedule(function()
				Lookup:show_popup(opts.query[ith], book)
			end)
		end)

		-- Job.chain(job1, job2)
		Job.chain(job1)
	end
end

function Lookup:add_footnote(html, book)
	for key, verse in pairs(book) do
		for ith, partial_verse in ipairs(verse) do
			for tag, id in pairs(partial_verse.footnotes) do
				Lookup.get_footnote(html, id, {
					on_exit = function(j, _, _)
						vim.schedule(function()
							local _result = table.concat(j:result(), "")
							book[key][ith].footnotes[tag] = _result
						end)
					end,
				}):start()
			end
		end
	end
end

function Lookup:show_popup(query, book)
	local _content = { query }
	for _, key in ipairs(sort_verse(book)) do
		for ith, partial_verse in ipairs(book[key]) do
			table.insert(_content, partial_verse.text)
		end
	end
	local popup = Popup()
	vim.api.nvim_buf_set_lines(popup.bufnr, -2, -1, false, _content)
	popup:mount()
end

function Lookup.get_footnote(input, id, opts)
	-- find
	local _pup1 = Lookup:pup("div.footnotes li" .. id, input)
	local _pup2 = Lookup:pup("text{}", _pup1, opts)
	return _pup2
end

function Lookup.get_verse(input, opts)
	local _pup1 = Lookup:pup('div[class="passage-text"]', input)
	local _pup2 = Lookup:pup(":not(sup.footnote)", _pup1)
	local _pup3 = Lookup:pup("span.text json{}", _pup2, opts)
	return _pup3
end

function Lookup:curl(opts, on_exit)
	local uris = Lookup:form_URL(opts)
	local responses = {}
	for _, uri in ipairs(uris) do
		local stdout_results = {}

		local job = Job:new({
			command = "curl",
			args = {
				"--silent",
				"--show-error",
				"--no-buffer",
				uri,
			},
			on_exit = on_exit,
			on_stdout = function(_, line)
				table.insert(stdout_results, line)
			end,
		})
		job:sync()
		table.insert(responses, stdout_results)
	end
	return responses
end

function Lookup:pup(query, prev_job, opts)
	opts = vim.tbl_extend("force", {
		command = "pup",
		args = { query },
		writer = prev_job,
	}, opts or {})
	return Job:new(opts)
end

function Lookup.encode(prev_job)
	local _job = Job:new({
		command = "python",
		args = {
			"-c",
			[["import sys; print(sys.stdin.read().encode('utf-8'))"]],
		},
		writer = prev_job,
		-- cwd = "/home/huy/go/bin",
		-- on_exit = on_exit and vim.schedule_wrap(on_exit) or nil,
	})
	return _job
end

local function process_element(element, parent)
	local output = {}
	parent = parent or {}
	-- if element.tag == "br" then
	-- 	table.insert(output, "<br>")

	local has_text, _ = string.find(element.class or "", "text")
	local has_versenum, _ = string.find(element.class or "", "versenum")
	local has_footnote, _ = string.find(element.class or "", "footnote")
	if has_text ~= nil then
		output.name = "text"
	end

	if has_versenum ~= nil then
		output.name = "versenum"
	end
	if has_footnote ~= nil then
		output.name = "footnote"
	end

	if element.text and element.href then
		-- table.insert(output, element.text)
		output.name = element.text
		output.value = element.href
	end

	if element.text then
		-- table.insert(output, element.text)
		output.value = element.text
	end

	if element.href then
		-- table.insert(output, element.text)
		output.value = element.href
	end

	if element.children then
		-- local _parent = process_element(element) -- process parent
		-- vim.tbl_extend("force", _parent, output)
		-- _parent.value = {}
		-- output.children = {}
		for _, child in ipairs(element.children) do
			local _output = process_element(child, parent)
			parent.value = _output
			-- table.insert(output.children, ith, process_element(child))
			-- vim.tbl_extend("force", output, _output)
		end
	end

	return output
end

local function process_json(json_data)
	local output = {}
	for _, top_level_element in ipairs(json_data) do
		vim.tbl_extend("force", output, process_element(top_level_element))
	end
	return table.concat(output)
end

-- 01/02/2024
function Lookup:extract_span_text(json, opts)
	opts = opts or {
		delimiter = "\n",
	}
	local book = {}

	for _, item in ipairs(json) do
		local cur_versenum = item.class
		local verse = {}
		verse.text = item.text
		verse.footnotes = {}
		if item.children then
			for _, child in ipairs(item.children) do
				if child.class == "versenum" then
					verse.versenum = child.text
				end
				if child.class == "footnote" then
					for _, _item in ipairs(child.children) do
						verse.footnotes[_item.text] = _item.href
					end
				end
			end
		end

		-- verse.verse = cur_versenum
		if not book[cur_versenum] then
			book[cur_versenum] = {}
		end
		table.insert(book[cur_versenum], verse)
	end
	return book
end

return Lookup
