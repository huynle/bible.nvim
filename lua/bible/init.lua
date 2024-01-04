-- local dev = require("hle.util.dev")
local config = require("bible.config")
local providers = require("bible.providers")
local View = require("bible.view")
local util = require("bible.util")
local tools = require("bible.util.tools")
local Popup = require("nui.popup")
-- local http = require("plenary.http")
local Job = require("plenary.job")
-- local popup = require("plenary.popup")

local Bible = {}

function Bible.setup(options)
	-- local options = get_opts(...)
	-- local options = vim.tbl_extend("force", options, config.defaults)

	-- dev.unload_packages("bible")
	config.setup(options)
	providers.setup(config.options.providers)

	require("bible.commands.builtin")
	-- print("sourced bible")
end

local views = {}

-- local function is_open()
--   local view = views[vim.fn.bufname()]
--   return view and view:is_valid()
-- end

function Bible.open(query, provider_options)
	-- local opts = get_opts(...)
	require("bible.providers").get(query, provider_options, function(results)
		local view = View.create(config.options, query, views)
		view:update(results, { focus = false })
	end)
end

function Bible.close()
	util.debug("got to close")
	-- local view = views[vim.api.nvim_get_current_buf()]
	-- local buf_name = vim.fn.bufname()
	if view:is_open() then
		view:close()
	end
end

function Bible.yank()
	util.debug("got to yan")
	local view = views[vim.api.nvim_get_current_buf()]
	local item = view:current_item()
	-- if is_open() then
	--   view:close()
	-- end
end

local function urlencode(params)
	local encoded_params = {}
	for key, value in pairs(params) do
		key = string.gsub(key, " ", "%%20") -- Encode spaces as %20
		value = string.gsub(value, " ", "%%20") -- Encode spaces as %20
		table.insert(encoded_params, key .. "=" .. value)
	end
	return table.concat(encoded_params, "&")
end

function Bible.formURL(ref, opts)
	opts = opts or {
		version = "NABRE",
	}
	local uri = "https://www.biblegateway.com/passage/"
	local params = {
		interface = "print",
		version = opts.version,
		search = ref,
	}
	uri = uri .. "?" .. urlencode(params)
	return uri
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

function Bible.fetchVerse(verseRef, opts)
	local response = Bible.curl(verseRef)

	local job1 = Bible.get_text_new(response, {
		on_exit = function(j, _, _)
			vim.schedule(function()
				local json = vim.fn.json_decode(j:result()) or {}
				local book = Bible.extract_span_text(json)
				local _content = {}

				for _, key in ipairs(sort_verse(book)) do
					for _, item in ipairs(book[key]) do
						table.insert(_content, item.text)
					end
				end
				Bible.open_popup(_content)
			end)
		end,
	})

	job1:start()
	job1:wait()
end

function Bible.get_text_new(input, opts)
	local _pup1 = Bible.pup('div[class="passage-text"]', input)
	local _pup2 = Bible.pup(":not(sup.footnote)", _pup1)
	local _pup3 = Bible.pup("span.text json{}", _pup2, opts)
	return _pup3
end

function Bible.get_text(curl)
	local book
	local _pup1 = Bible.pup('div[class="passage-text"]', curl)
	local _pup2 = Bible.pup(":not(sup.footnote)", _pup1)
	local _pup3 = Bible.pup("span.text json{}", _pup2)
	_pup3:sync()

	local json = vim.fn.json_decode(_pup3:result()) or {}
	book = Bible.extract_span_text(json)
	return book
end

function Bible.curl(verseRef, on_exit)
	local uri = Bible.formURL(verseRef)
	local stdout_results = {}

	Job:new({
		command = "curl",
		args = {
			"--silent",
			"--show-error",
			"--no-buffer",
			uri,
		},
		writer = nil,
		on_exit = on_exit,
		on_stdout = function(_, line)
			table.insert(stdout_results, line)
		end,
	}):sync()

	return stdout_results
end

function Bible.pup(query, prev_job, opts)
	opts = vim.tbl_extend("force", {
		command = "pup",
		args = { query },
		writer = prev_job,
	}, opts or {})
	return Job:new(opts)
end

function Bible.encode(prev_job)
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

function Bible.output_table(lua_table)
	local processed_output = process_json(lua_table)
	return processed_output

	-- Bible.open_popup(processed_output)
end

-- 01/02/2024
function Bible.extract_span_text(json, opts)
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

function Bible.open_popup(content)
	local popup_options = {
		position = "50%",
		size = {
			width = 80,
			height = 40,
		},
		enter = true,
		focusable = true,
		zindex = 50,
		relative = "editor",
		border = {
			padding = {
				top = 2,
				bottom = 2,
				left = 3,
				right = 3,
			},
			style = "rounded",
			-- text = {
			-- 	top = " I am top title ",
			-- 	top_align = "center",
			-- 	bottom = "I am bottom title",
			-- 	bottom_align = "left",
			-- },
		},
		buf_options = {
			modifiable = true,
			readonly = true,
		},
		win_options = {
			winblend = 10,
			winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
		},
	}

	local panel = Popup(popup_options)

	-- local bufnr = vim.api.nvim_win_get_buf(win_id)
	panel:map("n", "q", "<cmd>lua vim.api.nvim_win_close(0, true)<CR>", { silent = true })
	panel:map("n", "<c-c>", "<cmd>lua vim.api.nvim_win_close(0, true)<CR>", { silent = true })

	vim.api.nvim_buf_set_lines(panel.bufnr, -2, -1, false, content)
	panel:mount()
end

function Bible.action(action)
	util.debug("GOT HERE " .. action)
	local buf_name = vim.fn.bufname()
	local view = views[buf_name]
	-- if action == "toggle_mode" then
	--   if config.options.mode == "document_diagnostics" then
	--     config.options.mode = "workspace_diagnostics"
	--   elseif config.options.mode == "workspace_diagnostics" then
	--     config.options.mode = "document_diagnostics"
	--   end
	--   action = "refresh"
	-- end

	if view and action == "on_win_enter" then
		view:on_win_enter()
	end
	if not view:is_open() then
		return Bible
	end
	-- if action == "hover" then
	--   view:hover()
	-- end
	if action == "jump" then
		view:jump()
	elseif action == "open_split" then
		view:jump({ precmd = "split" })
	elseif action == "open_vsplit" then
		view:jump({ precmd = "vsplit" })
	elseif action == "open_tab" then
		view:jump({ precmd = "tabe" })
	end
	if action == "jump_close" then
		view:jump()
		Bible.close()
	end
	if action == "open_folds" then
		Bible.refresh({ open_folds = true })
	end
	if action == "close_folds" then
		Bible.refresh({ close_folds = true })
	end
	if action == "toggle_fold" then
		view:toggle_fold()
	end
	if action == "on_enter" then
		view:on_enter()
	end
	if action == "on_leave" then
		view:on_leave()
	end
	if action == "close" then
		view:close()
		views[buf_name] = nil
		return Bible
	end
	if action == "cancel" then
		view:switch_to_parent()
	end
	if action == "next" then
		view:next_item()
		return Bible
	end
	if action == "previous" then
		view:previous_item()
		return Bible
	end

	-- if action == "toggle_preview" then
	--   config.options.auto_preview = not config.options.auto_preview
	--   if not config.options.auto_preview then
	--     view:close_preview()
	--   else
	--     action = "preview"
	--   end
	-- end
	-- if action == "auto_preview" and config.options.auto_preview then
	--   action = "preview"
	-- end
	-- if action == "preview" then
	--   view:preview()
	-- end

	--util.debug("again...")

	if Bible[action] then
		Bible[action]()
	end
	return Bible
end

return Bible
