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

function Lookup:fetch_verse(opts)
	-- fetch the bible verse and extract only text
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

	local response = self:curl(opts)

	local _job = self:get_verse(response, {
		on_exit = vim.schedule_wrap(function(j)
			local ok, json = pcall(vim.fn.json_decode, j:result())
			if ok then
				self:extract_span_text(json)
				self.renderer:prepare_tree(opts)
				self.renderer:render()
			end
		end),
	})

	_job:after(vim.schedule_wrap(function()
		self:add_footnote(response)
	end))

	_job:start()
end

function Lookup:add_footnote(html)
	-- asynchronously run in the back and get footnotes updated
	for key, verse in pairs(self.book) do
		for ith, partial_verse in ipairs(verse) do
			for tag, id in pairs(partial_verse.footnotes) do
				local _job = self:get_footnote(html, id, {
					on_exit = vim.schedule_wrap(function(j, _, _)
						local _result = {}
						for _, item in ipairs(j:result()) do
							if not utils.isempty(item) then
								table.insert(_result, item)
							end
						end
						local name = self.book[key][ith].footnotes[tag]
						self.ref[name] = table.concat(_result, "")
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

-- 01/02/2024
function Lookup:extract_span_text(json, opts)
	opts = opts or {
		delimiter = "\n",
	}
	local _book = {}

	for _, item in ipairs(json) do
		local cur_versenum = item.class
		local verse = {}
		verse.text = self:iconv(item.text)
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
		if not _book[cur_versenum] then
			_book[cur_versenum] = {}
		end
		table.insert(_book[cur_versenum], verse)
	end
	self.book = vim.tbl_extend("force", self.book, _book)
end

return Lookup
