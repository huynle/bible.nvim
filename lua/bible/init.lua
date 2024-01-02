-- local dev = require("hle.util.dev")
local config = require("bible.config")
local providers = require("bible.providers")
local View = require("bible.view")
local util = require("bible.util")
local tools = require("bible.util.tools")
-- local http = require("plenary.http")
local Job = require("plenary.job")

local Bible = {}

local function get_opts(...)
	local args = { ... }
	if vim.tbl_islist(args) and #args == 1 and type(args[1]) == "table" then
		args = args[1]
	end
	local opts = {}
	for key, value in pairs(args) do
		if type(key) == "number" then
			local k, v = value:match("^(.*)=(.*)$")
			if k then
				opts[k] = v
			elseif opts.mode then
			-- util.error("unknown option " .. value)
			else
				opts.mode = value
			end
		else
			opts[key] = value
		end
	end
	opts = opts or {}
	-- util.fix_mode(opts)
	config.options = opts
	return opts
end

function Bible.setup(options)
	-- local options = get_opts(...)
	-- local options = vim.tbl_extend("force", options, config.defaults)

	-- dev.unload_packages("bible")
	config.setup(options)
	providers.setup(config.options.providers)

	require("bible.commands.builtin")
	print("sourced bible")
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

-- Function to handle stdout data

-- Spawn the curl command
function Bible.exec(cmd, args)
	local stdout = vim.loop.new_pipe(false)
	local stderr = vim.loop.new_pipe(false)

	local handle
	handle = vim.loop.spawn(
		cmd,
		{
			args = args,
			stdio = { nil, stdout, stderr }, -- Redirect stdout to a pipe
		},
		vim.schedule_wrap(function()
			stdout:read_stop()
			stderr:read_stop()
			stdout:close()
			stderr:close()
			if handle ~= nil then
				handle:close()
			end
		end)
	)

	local results = {}

	local function onread(err, data)
		results = data
		if err then
			-- Handle error
			print("Error reading stdout:", err)
			return
		end

		if data then
			-- results = data
			-- Process the received data (stdout)
			print("Received data:", data)
		else
			-- Finished reading stdout
			print("Finished reading data")
		end
	end

	vim.loop.read_start(stdout, onread)
	vim.loop.read_start(stderr, onread)

	return results
end

function Bible.fetchVerse(verseRef, opts)
	opts = opts or {
		delimiter = "\n",
	}
	local text = {}
	local curl = Bible.curl(verseRef)
	local _pup1 = Bible.pup('div[class="passage-text"]', curl)
	local _pup2 = Bible.pup(":not(sup.footnote)", _pup1)
	local _pup3 = Bible.pup("span.text json{}", _pup2, function(j, _, _)
		local json = vim.fn.json_decode(j:result())
		for _, item in ipairs(json) do
			table.insert(text, item.text)
		end
		local verse = table.concat(text, opts.delimiter or "\n")
		dump(verse)
	end)

	_pup3:start()
end

function Bible.curl(verseRef)
	local uri = Bible.formURL(verseRef)

	return Job:new({
		command = "curl",
		args = {
			"--silent",
			"--show-error",
			"--no-buffer",
			uri,
		},
		writer = nil,
		cwd = "/usr/bin",
	})
end

function Bible.pup(query, prev_job, on_exit)
	local _job = Job:new({
		command = "pup",
		args = { query },
		writer = prev_job,
		cwd = "/home/huy/go/bin",
		on_exit = on_exit and vim.schedule_wrap(on_exit) or nil,
	})
	return _job
end

function Bible.extractText(html)
	local cb = function(...)
		print(...)
	end

	Bible.exec("pup", {
		'div[class="passage-text"]',
	}, function(chunk) end, function(err, _)
		cb(err)
	end, function() end, function(chunk)
		cb(chunk, "passage-text")
	end)

	return nil
end

local START_READ_CONTENT_RE = "<h1 class=['\"]passage-display['\"]>"
local END_READ_CONTENT_RE = "^<script "
local DEFAULT_VERSION = "NABRE" -- Default Bible version

local opts = {
	boldwords = false,
	copyright = true,
	headers = true,
	footnotes = true,
	verbose = false,
	newline = false,
	numbering = true,
	crossrefs = true,
	filename = "", -- File name for test HTML (if needed)
	version = DEFAULT_VERSION, -- Default Bible version
}

local function urlencode(params)
	local encoded_params = {}
	for key, value in pairs(params) do
		key = string.gsub(key, " ", "%%20") -- Encode spaces as %20
		value = string.gsub(value, " ", "%%20") -- Encode spaces as %20
		table.insert(encoded_params, key .. "=" .. value)
	end
	return table.concat(encoded_params, "&")
end

function Bible.formURL(ref)
	local uri = "https://www.biblegateway.com/passage/"
	local params = {
		interface = "print",
		version = opts.version,
		search = ref,
	}
	uri = uri .. "?" .. urlencode(params)
	return uri
end

function Bible.extractInterestingContent(lines)
	local input_lines = {}
	local n = 0
	local in_interesting = false

	for _, line in ipairs(lines) do
		if string.match(line, START_READ_CONTENT_RE) then
			in_interesting = true
		end

		if in_interesting then
			if string.match(line, END_READ_CONTENT_RE) then
				break
			end

			local updated_line = line:match("^%s*(.-)%s*$")
			if updated_line ~= "" then
				input_lines[n + 1] = updated_line
				n = n + 1
			end
		end
	end

	return input_lines
end

function Bible.realistic_func()
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_command("sbuffer " .. buf)
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
