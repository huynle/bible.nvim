local M = {}

M.namespace = vim.api.nvim_create_namespace("Bible")

local defaults = {
	lookup_defaults = {
		version = "NABRE",
		query = "Genesis 1:1",
	},
	yank_register = "+",
	popup_window = {
		position = 1,
		padding = { 1, 1, 1, 1 },
		size = {
			width = "50%",
			-- height = 10,
			height = "50%",
		},
		enter = false,
		focusable = true,
		zindex = 50,
		relative = "cursor",
		border = {
			style = "rounded",
		},
		buf_options = {
			modifiable = false,
			-- readonly = true,
		},
		win_options = {
			wrap = true,
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
}

M.options = {}

function M.setup(options)
	M.options = vim.tbl_deep_extend("force", {}, defaults, options or {})
end

M.setup()

return M
