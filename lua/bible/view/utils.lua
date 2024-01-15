local config = require("bible.config")
local event = require("nui.utils.autocmd").event
local M = {}

function M.set_buf_options(popup, opts)
	vim.api.nvim_buf_set_option(popup.bufnr, "filetype", "bible")
end

function M.do_keymap(popup, opts)
	-- close
	local keys = config.options.view.keymaps.close
	if type(keys) ~= "table" then
		keys = { keys }
	end
	for _, key in ipairs(keys) do
		popup:map("n", key, function()
			if opts.stop and type(opts.stop) == "function" then
				opts.stop()
			end
			popup:unmount()
			vim.cmd("q")
		end)
	end

	-- accept output and replace
	popup:map("n", config.options.view.keymaps.accept, function()
		local _lines = vim.api.nvim_buf_get_lines(popup.bufnr, 0, -1, false)
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
	popup:map("n", config.options.view.keymaps.prepend, function()
		if opts.main_bufnr then
			local _lines = vim.api.nvim_buf_get_lines(popup.bufnr, 0, -1, false)
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
	popup:map("n", config.options.view.keymaps.append, function()
		if opts.main_bufnr then
			local _lines = vim.api.nvim_buf_get_lines(popup.bufnr, 0, -1, false)
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
	popup:map("n", config.options.view.keymaps.yank_code, function()
		local _lines = vim.api.nvim_buf_get_lines(popup.bufnr, 0, -1, false)
		local _code = _lines
		vim.fn.setreg(config.options.yank_register, _code)

		if vim.fn.mode() == "i" then
			vim.api.nvim_command("stopinsert")
		end
		vim.cmd("q")
	end)

	-- yank output and close
	popup:map("n", config.options.view.keymaps.yank_to_register, function()
		local _lines = vim.api.nvim_buf_get_lines(popup.bufnr, 0, -1, false)
		vim.fn.setreg(config.options.yank_register, _lines)

		if vim.fn.mode() == "i" then
			vim.api.nvim_command("stopinsert")
		end
		vim.cmd("q")
	end)

	-- -- unmount component when cursor leaves buffer
	-- popup:on(event.BufLeave, function()
	--   action.stop = true
	--   popup:unmount()
	-- end)

	-- unmount component when cursor leaves buffer
	popup:on(event.WinClosed, function()
		if opts.stop and type(opts.stop) == "function" then
			opts.stop()
		end
		popup:unmount()
	end)

	-- dynamically resize
	-- https://github.com/MunifTanjim/nui.nvim/blob/main/lua/nui/split/README.md#splitupdate_layout
	-- popup:on(event.CursorMoved, function()
	-- 	-- popup:update_split_size(opts)
	-- end)
end

return M
