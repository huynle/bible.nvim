local Popup = require("nui.popup")
local config = require("bible.config")
local view_utils = require("bible.view.utils")

local PopupWindow = Popup:extend("PopupWindow")

function PopupWindow:init(options)
	options = vim.tbl_deep_extend("keep", options or {}, config.options.popup_window)
	options = vim.tbl_deep_extend("keep", options or {}, config.options.view)
	self.opts = options
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

function PopupWindow:mount(opts)
	opts = opts or {}
	opts = vim.tbl_extend("force", self.opts, opts)

	PopupWindow.super.mount(self)
	view_utils.do_keymap(self, opts)
end

return PopupWindow
