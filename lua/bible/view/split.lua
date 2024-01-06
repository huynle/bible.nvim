local Split = require("nui.split")
local config = require("bible.config")
local event = require("nui.utils.autocmd").event

local SplitWindow = Split:extend("SplitWindow")

function SplitWindow:init(options)
	options = vim.tbl_deep_extend("keep", options or {}, config.options.split_window)
	options = vim.tbl_deep_extend("keep", options or {}, config.options.view)
	self.opts = options
	SplitWindow.super.init(self, options)
end

function SplitWindow:mount(opts)
	opts = opts or {}
	opts = vim.tbl_extend("force", self.opts, opts)

	SplitWindow.super.mount(self)

	-- close
	local keys = config.options.view.keymaps.close
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
	self:map("n", config.options.view.keymaps.accept, function()
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
	self:map("n", config.options.view.keymaps.prepend, function()
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
	self:map("n", config.options.view.keymaps.append, function()
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
	self:map("n", config.options.view.keymaps.yank_code, function()
		local _lines = vim.api.nvim_buf_get_lines(self.bufnr, 0, -1, false)
		local _code = _lines
		vim.fn.setreg(config.options.yank_register, _code)

		if vim.fn.mode() == "i" then
			vim.api.nvim_command("stopinsert")
		end
		vim.cmd("q")
	end)

	-- yank output and close
	self:map("n", config.options.view.keymaps.yank_to_register, function()
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
	-- https://github.com/MunifTanjim/nui.nvim/blob/main/lua/nui/split/README.md#splitupdate_layout
	-- self:on(event.CursorMoved, function()
	-- 	-- self:update_split_size(opts)
	-- end)
end

return SplitWindow
