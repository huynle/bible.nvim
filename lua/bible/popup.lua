local Popup = require("nui.popup")
local config = require("bible.config")
local event = require("nui.utils.autocmd").event
local NuiTree = require("nui.tree")
local utils = require("bible.utils")

local PopupWindow = Popup:extend("PopupWindow")

function PopupWindow:init(lookup, options)
	options = vim.tbl_deep_extend("keep", options or {}, config.options.popup_window)
	self.opts = options
	self.lookup = lookup

	PopupWindow.super.init(self, options)
end

function PopupWindow:update_popup_size(opts)
	opts.lines = vim.api.nvim_buf_get_lines(self.bufnr, 0, -1, false)
	local ui_opts = self:calculate_size(opts)
	self:update_layout(ui_opts)
end

function PopupWindow:calculate_size(opts)
	opts = opts or {}
	-- compute size
	-- the width is calculated based on the maximum number of lines and the height is calculated based on the width
	local cur_win = opts.cur_win or vim.api.nvim_get_current_win()
	local max_h = math.ceil(vim.api.nvim_win_get_height(cur_win) * 0.75)
	local max_w = math.ceil(vim.api.nvim_win_get_width(cur_win) * 0.5)
	local ui_w = 0
	local len = 0
	local ncount = 0
	local lines = opts.lines

	for _, v in ipairs(lines) do
		local l = string.len(v)
		if v == "" then
			ncount = ncount + 1
		end
		ui_w = math.max(l, ui_w)
		len = len + l
	end
	ui_w = math.min(ui_w, max_w)
	ui_w = math.max(ui_w, 10)
	local ui_h = math.ceil(len / ui_w) + ncount
	ui_h = math.min(ui_h, max_h)
	ui_h = math.max(ui_h, 1)

	-- use opts
	ui_w = opts.ui_w or ui_w
	ui_h = opts.ui_h or ui_h

	-- build ui opts
	return {
		size = {
			width = ui_w,
			height = ui_h,
		},
		border = {
			style = "rounded",
			text = {
				top = " " .. (opts.title or opts.name or opts.args or "") .. " ",
				top_align = "left",
			},
		},
		relative = {
			type = "buf",
			position = {
				row = opts.selection_idx.start_row,
				col = opts.selection_idx.start_col,
			},
		},
	}
end

function PopupWindow:render_text()
	local _content = {}
	for _, key in ipairs(utils.sort_verse(self.lookup.book)) do
		for ith, partial_verse in ipairs(self.lookup.book[key]) do
			table.insert(_content, partial_verse.text)
		end
	end

	vim.api.nvim_buf_set_lines(self.bufnr, -2, -1, false, _content)
end

function PopupWindow:render_tree()
	-- vim.api.nvim_buf_set_lines(self.bufnr, -2, -1, false, content)
	local nodes = {}
	for _, key in ipairs(utils.sort_verse(self.lookup.book)) do
		for ith, partial_verse in ipairs(self.lookup.book[key]) do
			-- prepend verse number
			local _line = { text = (partial_verse.versenum or "") .. "\t" .. (partial_verse.text or "") }
			local _footnotes = {}
			for tag, footnote in pairs(partial_verse.footnotes) do
				table.insert(_footnotes, NuiTree.Node({ text = footnote }))
			end

			local _node
			if not vim.tbl_isempty(_footnotes) then
				_node = NuiTree.Node(_line, _footnotes)
			else
				_node = NuiTree.Node(_line)
			end

			table.insert(nodes, _node)
		end
	end

	local tree = NuiTree({
		bufnr = self.bufnr,
		nodes = nodes,
	})

	tree:render()

	-- toggle node
	self:map("n", config.options.popup_window.keymaps.toggle, function()
		local linenr = vim.api.nvim_win_get_cursor(self.winid)[1]
		local _node = tree:get_node(linenr)
		if _node:is_expanded() then
			_node:collapse()
		else
			_node:expand()
		end

		tree:render()
	end)
end

function PopupWindow:mount(opts)
	opts = opts or {}
	opts = vim.tbl_extend("force", self.opts, opts)
	-- self:render_text(content)
	self:render_tree()

	PopupWindow.super.mount(self)

	-- self:update_popup_size(opts)

	-- close
	local keys = config.options.popup_window.keymaps.close
	if type(keys) ~= "table" then
		keys = { keys }
	end
	for _, key in ipairs(keys) do
		self:map("n", key, function()
			if opts.stop and type(opts.stop) == "function" then
				opts.stop()
			end
			self:unmount()
		end)
	end

	-- accept output and replace
	self:map("n", config.options.popup_window.keymaps.accept, function()
		local _lines = vim.api.nvim_buf_get_lines(self.bufnr, 0, -1, false)
		-- vim.api.nvim_buf_set_text(
		-- 	opts.main_bufnr,
		-- 	opts.selection_idx.start_row - 1,
		-- 	opts.selection_idx.start_col - 1,
		-- 	opts.selection_idx.end_row - 1,
		-- 	opts.selection_idx.end_col,
		-- 	opts.lines
		-- )
		vim.cmd("q")
	end)

	-- accept output and prepend
	self:map("n", config.options.popup_window.keymaps.prepend, function()
		if opts.main_bufnr then
			local _lines = vim.api.nvim_buf_get_lines(self.bufnr, 0, -1, false)
			table.insert(_lines, "")
			table.insert(_lines, "")
			vim.api.nvim_buf_set_text(
				opts.main_bufnr,
				opts.selection_idx.end_row - 1,
				opts.selection_idx.start_col - 1,
				opts.selection_idx.end_row - 1,
				opts.selection_idx.start_col - 1,
				_lines
			)
		end
		vim.cmd("q")
	end)

	-- accept output and append
	self:map("n", config.options.popup_window.keymaps.append, function()
		if opts.main_bufnr then
			local _lines = vim.api.nvim_buf_get_lines(self.bufnr, 0, -1, false)
			table.insert(_lines, 1, "")
			table.insert(_lines, "")
			vim.api.nvim_buf_set_text(
				opts.main_bufnr,
				opts.selection_idx.end_row,
				opts.selection_idx.start_col - 1,
				opts.selection_idx.end_row,
				opts.selection_idx.start_col - 1,
				_lines
			)
		end
		vim.cmd("q")
	end)

	-- yank code in output and close
	self:map("n", config.options.popup_window.keymaps.yank_code, function()
		local _lines = vim.api.nvim_buf_get_lines(self.bufnr, 0, -1, false)
		local _code = _lines
		vim.fn.setreg(config.options.yank_register, _code)

		if vim.fn.mode() == "i" then
			vim.api.nvim_command("stopinsert")
		end
		vim.cmd("q")
	end)

	-- yank output and close
	self:map("n", config.options.popup_window.keymaps.yank_to_register, function()
		local _lines = vim.api.nvim_buf_get_lines(self.bufnr, 0, -1, false)
		vim.fn.setreg(Config.options.yank_register, _lines)

		if vim.fn.mode() == "i" then
			vim.api.nvim_command("stopinsert")
		end
		vim.cmd("q")
	end)

	-- -- unmount component when cursor leaves buffer
	-- self:on(event.BufLeave, function()
	--   action.stop = true
	--   self:unmount()
	-- end)

	-- unmount component when cursor leaves buffer
	self:on(event.WinClosed, function()
		if opts.stop and type(opts.stop) == "function" then
			opts.stop()
		end
		self:unmount()
	end)

	-- dynamically resize
	-- https://github.com/MunifTanjim/nui.nvim/blob/main/lua/nui/popup/README.md#popupupdate_layout
	-- self:on(event.CursorMoved, function()
	-- 	-- self:update_popup_size(opts)
	-- end)
end

return PopupWindow
