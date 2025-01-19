local Popup = require("bible.view.popup")
local Split = require("bible.view.split")
local Job = require("plenary.job")
local Object = require("bible.common.object")
local config = require("bible.config")
local utils = require("bible.utils")
local Renderer = require("bible.renderer")

local Lookup = Object("Lookup")

function Lookup:init(opts)
	self.opts = vim.tbl_extend("force", config.options.lookup_defaults, opts or {})
	self.book = {}
	self.ref = {}
	self.view = self:get_view(self.opts)
	self.renderer = Renderer(self, self.view)
	self.cur_win = vim.api.nvim_get_current_win()
end

function Lookup:get_view(opts)
	if opts.view == "split" then
		return Split()
	elseif opts.view == "below" then
		return Split({
			relative = "win",
			position = "bottom",
		})
	elseif opts.view == "right" then
		return Split({
			relative = "editor",
			position = "right",
		})
	elseif opts.view == "testing" then
		return Split({
			relative = {
				type = "win",
				winid = vim.api.nvim_get_current_win(),
			},
		})
	else
		return Popup()
	end
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

function Lookup:form_URL(opts)
	opts = vim.tbl_extend("force", self.opts, opts or {})

	local uri = "https://www.biblegateway.com/passage/"
	local params = {
		interface = "print",
		version = opts.versions[1],
		search = utils.urlencode_value(opts.query),
	}
	return uri .. "?" .. utils.urlencode(params)
end

--- Fetches Bible verses either from cache or from the web.
--- This function first checks if all requested verses are available in the cache.
--- If any verse is missing, it fetches the entire passage from the web, updates
--- the cache, and renders the verses in the view.
---
--- @param opts table Optional settings that override default options
function Lookup:fetch_verse(opts)
	opts = vim.tbl_extend("force", self.opts, opts or {})

	local _, start_row, start_col, end_row, end_col = self:get_visual_selection()

	local popup_opts = {
		main_bufnr = self:get_bufnr(),
		title = opts.query,
		cur_win = self.cur_win,
		selection_idx = {
			start_row = start_row,
			start_col = start_col,
			end_row = end_row,
			end_col = end_col,
		},
	}

	self.view:mount(popup_opts)

	-- Parse query to get book, chapter, and verse
	local book, chapter, verses = self:parse_reference(opts.query)

	-- If no verses specified but chapter is specified, fetch all verses in chapter
	-- If no chapter specified, fetch entire book
	-- This will be handled by the web request, as BibleGateway supports this format

	-- Check cache first
	local cache_file = utils.get_cache_file()
	local cache = utils.read_cache(cache_file)
	local version = opts.versions[1]

	-- Check if all verses exist in cache
	local all_verses_cached = true
	local cached_verses = {}

	-- Only check cache if specific verses were requested
	if #verses > 0 then
		-- Verify each verse exists in cache
		for _, verse_num in ipairs(verses) do
			local cached_verse = utils.get_cached_verse(cache, version, book, chapter, verse_num)
			if cached_verse then
				cached_verses[verse_num] = cached_verse
			else
				all_verses_cached = false
				break
			end
		end

		if all_verses_cached then
			-- Store all cached verses in self.book for the renderer to use
			for verse_num, cached_verse in pairs(cached_verses) do
				local verse_key = string.format("%s-%d-%d", book, chapter, verse_num)
				self.book[verse_key] = {
					{
						text = cached_verse.text,
						versenum = cached_verse.verse,
						footnotes = cached_verse.footnotes or {}, -- Use cached footnotes
					},
				}
				-- Store footnotes in self.ref for rendering
				if cached_verse.footnotes then
					for tag, footnote in pairs(cached_verse.footnotes) do
						self.ref[footnote.id] = footnote.text
					end
				end
			end
			self.renderer:prepare_tree(opts)
			self.renderer:render()
			return
		end
	end

	-- If any verse is not cached or if no specific verses were requested, fetch from web
	local response = self:curl(opts)

	local _job = self:get_verse(response, {
		on_exit = vim.schedule_wrap(function(j)
			local ok, json = pcall(vim.fn.json_decode, j:result())
			if ok then
				-- Extract and cache verse data
				local verse_data = self:extract_span_text(json)
				utils.cache_verse_data(cache, version, book, chapter, verse_data)

				-- Store the verse data in self.book for the renderer to use
				for _, data in ipairs(verse_data) do
					local verse_key = string.format("%s-%d-%d", book, data.chapter, data.verse)
					self.book[verse_key] = {
						{
							text = data.text,
							versenum = data.verse,
							footnotes = data.footnotes or {}, -- Include footnotes
						},
					}
				end
				utils.write_cache(cache_file, cache)

				-- Update footnotes in cache after they're fetched
				self:add_footnote(response)

				self.renderer:prepare_tree(opts)
				self.renderer:render()
			end
		end),
	})

	_job:start()
end

--- Asynchronously fetches and caches footnotes for Bible verses.
--- This function processes footnotes for each verse in the book, fetches the footnote content,
--- and stores it in the cache for future use.
--- @param html table The HTML content containing the footnotes
function Lookup:add_footnote(html)
	local cache_file = utils.get_cache_file()
	local cache = utils.read_cache(cache_file)

	-- Asynchronously run in the background and get footnotes updated
	for key, verse in pairs(self.book) do
		for ith, partial_verse in ipairs(verse) do
			for tag, id in pairs(partial_verse.footnotes) do
				local _job = self:get_footnote(html, id, {
					on_exit = vim.schedule_wrap(function(j, _, _)
						local _result = {}
						for _, item in ipairs(j:result()) do
							if not utils.isempty(item) then
								-- First trim whitespace
								local trimmed = item:match("^%s*(.-)%s*$")
								table.insert(_result, trimmed)
							end
						end

						-- Get the footnote ID
						local footnote_id = self.book[key][ith].footnotes[tag]
						local footnote_text = table.concat(_result, " ")

						-- Update the footnote text in the cache
						utils.update_footnote_text(cache, footnote_id, footnote_text)

						-- Write the updated cache back to file
						utils.write_cache(cache_file, cache)

						-- Also update self.ref for immediate use in the current session
						self.ref[footnote_id] = footnote_text
					end),
				})
				_job:start()
			end
		end
	end
end

function Lookup:get_popup(query)
	return Popup(self)
end

function Lookup:get_footnote(input, id, opts)
	-- find
	local _pup1 = self:pup("div.footnotes li" .. id, input)
	local _pup2 = self:pup("text{}", _pup1, opts)
	return _pup2
end

function Lookup:get_verse(input, opts)
	local _pup1 = self:pup('div[class="passage-text"]', input)
	local _pup2 = self:pup(":not(sup.footnote)", _pup1)
	local _pup3 = self:pup("span.text json{}", _pup2, opts)
	return _pup3
end

function Lookup:curl(opts, on_exit)
	opts = vim.tbl_extend("force", self.opts, opts or {})

	local uri = self:form_URL(opts)
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
	return stdout_results
end

function Lookup:pup(query, prev_job, opts)
	opts = vim.tbl_extend("force", {
		command = "pup",
		args = { query },
		writer = prev_job,
	}, opts or {})
	return Job:new(opts)
end

function Lookup:iconv(item)
	if type(item) ~= "string" then
		return item
	end
	item = item:gsub([[\u00A0]], "")
	item = item:gsub([[&nbsp;]], " ")
	item = item:gsub([[&amp;]], "&")
	item = item:gsub([[“]], '"')
	item = item:gsub([[”]], '"')
	item = item:gsub([[‘]], "'")
	item = item:gsub([[’]], "'")
	item = item:gsub([[—]], "--")
	item = item:gsub("Ã¢â‚¬â„¢", "'")
	item = item:gsub("Ã¢â‚¬Ëœ", "'")
	item = item:gsub("Ã¢â‚¬Å", "")
	item = item:gsub("Ã¢â‚¬ï¿½", "")
	item = item:gsub("Ã¢â‚¬â€�", "—")
	return item
end

-- Parse a Bible reference string into its components.
-- @param query string: A Bible reference in the format "Book Chapter:Verse" or "Book Chapter:Verse-Verse"
--   Examples:
--     - "Genesis 1:1"
--     - "Ecclesiastes 2:1-10"
--     - "Ecclesiastes 2:1-10, 11, 13-20"\
--
-- Based on the context, this is part of a Bible reference parsing function, and for consistency in handling book names, you'd want to use standardized abbreviations. Here's a common way to represent Ecclesiastes and other Bible books using standard abbreviations:
--
-- For Ecclesiastes specifically, the standard abbreviations are:
-- - Eccl
-- - Ecc
-- - Ec
--
-- For a complete standardized system, here are the common abbreviations for all Bible books:
--
-- Old Testament:
-- Gen, Ex, Lev, Num, Deut, Josh, Judg, Ruth, 1Sam, 2Sam, 1Kgs, 2Kgs, 1Chr, 2Chr, Ezra, Neh, Est, Job, Ps, Prov, Eccl, Song, Isa, Jer, Lam, Ezek, Dan, Hos, Joel, Amos, Obad, Jon, Mic, Nah, Hab, Zeph, Hag, Zech, Mal
--
-- New Testament:
-- Matt, Mark, Luke, John, Acts, Rom, 1Cor, 2Cor, Gal, Eph, Phil, Col, 1Thess, 2Thess, 1Tim, 2Tim, Titus, Phlm, Heb, Jas, 1Pet, 2Pet, 1John, 2John, 3John, Jude, Rev
--
-- These abbreviations are widely recognized and would be appropriate to use in the `book` variable of the parsing function.
--
-- @return string: The book name
-- @return number: The chapter number
-- @return table: A list of verse numbers
function Lookup:parse_reference(query)
	-- Try to match full reference (book chapter:verses)
	local book, chapter, verses = query:match("([%w%s]+)%s*(%d+):(.+)")

	if not book then
		-- Try to match book and chapter only
		book, chapter = query:match("([%w%s]+)%s*(%d+)")
	end

	if not book then
		-- Try to match book only
		book = query:match("([%w%s]+)")
	end

	-- Standardize book names
	local book_mappings = {
		-- Old Testament
		["Genesis"] = "Gen",
		["Exodus"] = "Ex",
		["Leviticus"] = "Lev",
		["Numbers"] = "Num",
		["Deuteronomy"] = "Deut",
		["Joshua"] = "Josh",
		["Judges"] = "Judg",
		["Ruth"] = "Ruth",
		["1 Samuel"] = "1Sam",
		["2 Samuel"] = "2Sam",
		["1 Kings"] = "1Kgs",
		["2 Kings"] = "2Kgs",
		["1 Chronicles"] = "1Chr",
		["2 Chronicles"] = "2Chr",
		["Ezra"] = "Ezra",
		["Nehemiah"] = "Neh",
		["Esther"] = "Est",
		["Job"] = "Job",
		["Psalms"] = "Ps",
		["Psalm"] = "Ps",
		["Proverbs"] = "Prov",
		["Ecclesiastes"] = "Eccl",
		["Song of Solomon"] = "Song",
		["Song of Songs"] = "Song",
		["Isaiah"] = "Isa",
		["Jeremiah"] = "Jer",
		["Lamentations"] = "Lam",
		["Ezekiel"] = "Ezek",
		["Daniel"] = "Dan",
		["Hosea"] = "Hos",
		["Joel"] = "Joel",
		["Amos"] = "Amos",
		["Obadiah"] = "Obad",
		["Jonah"] = "Jon",
		["Micah"] = "Mic",
		["Nahum"] = "Nah",
		["Habakkuk"] = "Hab",
		["Zephaniah"] = "Zeph",
		["Haggai"] = "Hag",
		["Zechariah"] = "Zech",
		["Malachi"] = "Mal",
		-- New Testament
		["Matthew"] = "Matt",
		["Mark"] = "Mark",
		["Luke"] = "Luke",
		["John"] = "John",
		["Acts"] = "Acts",
		["Romans"] = "Rom",
		["1 Corinthians"] = "1Cor",
		["2 Corinthians"] = "2Cor",
		["Galatians"] = "Gal",
		["Ephesians"] = "Eph",
		["Philippians"] = "Phil",
		["Colossians"] = "Col",
		["1 Thessalonians"] = "1Thess",
		["2 Thessalonians"] = "2Thess",
		["1 Timothy"] = "1Tim",
		["2 Timothy"] = "2Tim",
		["Titus"] = "Titus",
		["Philemon"] = "Phlm",
		["Hebrews"] = "Heb",
		["James"] = "Jas",
		["1 Peter"] = "1Pet",
		["2 Peter"] = "2Pet",
		["1 John"] = "1John",
		["2 John"] = "2John",
		["3 John"] = "3John",
		["Jude"] = "Jude",
		["Revelation"] = "Rev",
		["Revelations"] = "Rev",
	}

	-- Clean and standardize the book name
	if book then
		book = book:match("^%s*(.-)%s*$") -- Trim whitespace
		book = book:gsub("^(%d)%s+", "%1 ") -- Standardize spacing after numbers
		book = book:gsub("(%a)(%d)", "%1 %2") -- Add space between letter and number

		-- Convert to title case for consistent lookup
		book = book:gsub("^%l", string.upper):gsub("%s+%l", string.upper)

		-- Look up the standardized abbreviation
		book = book_mappings[book] or book
	end

	-- Initialize verses table
	local verse_list = {}

	-- Only process verses if they were provided
	if verses then
		-- Split verses by comma
		for verse_range in verses:gmatch("[^,]+") do
			-- Trim whitespace
			verse_range = verse_range:match("^%s*(.-)%s*$")

			-- Check if it's a range (contains hyphen)
			local start_verse, end_verse = verse_range:match("(%d+)-(%d+)")
			if start_verse and end_verse then
				-- Add all verses in the range
				for v = tonumber(start_verse), tonumber(end_verse) do
					table.insert(verse_list, v)
				end
			else
				-- Single verse
				local single_verse = tonumber(verse_range)
				if single_verse then
					table.insert(verse_list, single_verse)
				end
			end
		end
	end

	return book, chapter and tonumber(chapter) or nil, verse_list
end

-- Updated extract_span_text function
function Lookup:extract_span_text_og(json)
	-- Modify this function to return structured verse data
	local verse_data = {
		verse = json.verse,
		text = json.text,
		reference = json.reference,
		-- Add other relevant fields you want to cache
	}
	return verse_data
end

function Lookup:extract_span_text(json)
	local verses = {}
	local current_chapter = nil
	local current_verse_data = nil

	for _, entry in ipairs(json) do
		-- Check for chapter number
		if entry.children then
			for _, child in ipairs(entry.children) do
				if child.class == "chapternum" then
					current_chapter = tonumber(child.text)
				end
			end
		end

		-- Extract verse information
		local new_verse = false
		if entry.class and entry.class:match("text%s+[%w%-]+%-(%d+)%-(%d+)") then
			local chapter, verse = entry.class:match("text%s+[%w%-]+%-(%d+)%-(%d+)")

			-- If we find a new verse, save the previous one (if exists) and create new verse_data
			if
				current_verse_data
				and (current_verse_data.verse ~= tonumber(verse) or current_verse_data.chapter ~= tonumber(chapter))
			then
				if #current_verse_data.text > 0 then
					table.insert(verses, current_verse_data)
				end
				new_verse = true
			end

			-- Create new verse_data for new verse
			if new_verse or not current_verse_data then
				-- Set verse to 0 if entry.text contains "Chapter", otherwise use the parsed verse number
				local verse_num = (entry.text:match(chapter) and entry.class:match(chapter .. "-" .. verse)) and 0 or tonumber(verse)
				current_verse_data = {
					verse = verse_num,
					text = {}, -- Initialize as empty table instead of empty string
					reference = entry.class:match("text%s+([%w%-]+%-%d+%-%d+)"),
					chapter = tonumber(chapter),
					footnotes = {},
				}
			end
		end

		-- Extract text content
		if current_verse_data then
			if entry.text then
				table.insert(current_verse_data.text, self:iconv(entry.text))
			end

			-- Process nested children if they exist
			if entry.children then
				for _, child in ipairs(entry.children) do
					if
						child.text
						and child.class ~= "chapternum"
						and child.class ~= "versenum"
						and child.class ~= "crossreference"
						and child.class ~= "footnote"
					then
						table.insert(current_verse_data.text, self:iconv(child.text))
					end

					-- Extract footnote information
					if child.class == "footnote" then
						local footnote_tag = child.text:match("%[(.-)%]")
						if footnote_tag and child["data-fn"] then
							current_verse_data.footnotes[footnote_tag] = child["data-fn"]
						end
					end
				end
			end
		end
	end

	-- Add the last verse if it exists
	if current_verse_data and #current_verse_data.text > 0 then
		-- Clean up each text entry
		for i, text in ipairs(current_verse_data.text) do
			current_verse_data.text[i] = text:gsub("%s+", " "):match("^%s*(.-)%s*$")
		end

		-- Add chapter information if available
		if current_chapter then
			current_verse_data.chapter = current_chapter
		end

		table.insert(verses, current_verse_data)
	end

	return verses
end

return Lookup
