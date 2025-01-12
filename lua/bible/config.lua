local M = {}

M.namespace = vim.api.nvim_create_namespace("Bible")

local defaults = {
	lookup_defaults = {
		versions = { "NABRE" },
		query = "Genesis 1:1",
		view = "split",
		show_header = {
			surround = "**",
		},
		numbering = true,
		footnotes = true,
	},
	yank_register = "+",
	view = {
		clear_old_windows = true,
		enter = true,
		buf_options = {
			modifiable = false,
			readonly = true,
		},
		win_options = {
			wrap = false,
			linebreak = true,
			-- winblend = 10,
			-- winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
			winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
		},

		keymaps = {
			close = { "<C-c>", "q" },
			accept = "<c-y>",
			toggle = "<CR>",
			append = "a",
			prepend = "p",
			yank_code = "c",
			yank_to_register = "y",
		},
	},
	split_window = {
		-- relative = {
		-- 	type = "win",
		-- 	winid = "42",
		-- },
		relative = "editor",
		position = "right",
		size = "35%",
		focusable = true,
	},
	popup_window = {
		position = 1,
		padding = { 1, 1, 1, 1 },
		size = {
			width = "50%",
			-- height = 10,
			height = "50%",
		},
		focusable = true,
		zindex = 50,
		relative = "cursor",
		border = {
			style = "rounded",
		},
	},
}

M.options = {}

function M.setup(options)
	M.options = vim.tbl_deep_extend("force", {}, defaults, options or {})
end

M.setup()

return M
