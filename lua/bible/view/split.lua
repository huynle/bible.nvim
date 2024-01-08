local Split = require("nui.split")
local config = require("bible.config")
local view_utils = require("bible.view.utils")

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
	view_utils.do_keymap(self, opts)
end

return SplitWindow
