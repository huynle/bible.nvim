local config = require("bible.config")
local NuiTree = require("nui.tree")
local NuiLine = require("nui.line")
local utils = require("bible.utils")
local classes = require("bible.common.classes")

local Renderer = classes.class()

function Renderer:init(lookup, view, options)
	self.opts = options
	self.lookup = lookup
	self.view = view

	self.tree = NuiTree({
		bufnr = self.view.bufnr,
		nodes = {},
		prepare_node = function(node)
			local line = NuiLine()
			line:append(string.rep("\t\t", node:get_depth() - 1))
			if self.lookup.opts.footnotes then
				if node:has_children() then
					line:append(node:is_expanded() and " " or " ")
				else
					line:append("  ")
				end
			end
			if node.is_footnote then
				line:append(self.lookup.ref[node.id] or node.id .. " not ready")
			else
				if self.lookup.opts.numbering then
					line:append((node.versenum or "") .. "\t\t" .. (node.text or ""))
				else
					line:append(node.text or "")
				end
			end
			return line
		end,
	})
end

function Renderer:render_text()
	local _content = {}
	for _, key in ipairs(utils.sort_verse(self.lookup.book)) do
		for ith, partial_verse in ipairs(self.lookup.book[key]) do
			table.insert(_content, partial_verse.text)
		end
	end

	vim.api.nvim_buf_set_lines(self.view.bufnr, -2, -1, false, _content)
end

function Renderer:prepare_tree(opts)
	opts = opts or {}
	opts = vim.tbl_extend("force", self.lookup.opts, opts)

	if opts.show_header then
		local _surround = {
			opts.show_header.surround,
			opts.query,
			opts.show_header.surround,
		}

		local _header = NuiTree.Node({ text = table.concat(_surround, " ") })
		self.tree:add_node(_header)
	end

	-- vim.api.nvim_buf_set_lines(self.bufnr, -2, -1, false, content)
	for _, key in ipairs(utils.sort_verse(self.lookup.book)) do
		for ith, partial_verse in ipairs(self.lookup.book[key]) do
			-- prepend verse number
			local _line = {
				text = partial_verse.text,
				versenum = partial_verse.versenum,
				is_verse = true,
			}
			local _footnotes = {}
			for tag, id in pairs(partial_verse.footnotes) do
				table.insert(
					_footnotes,
					NuiTree.Node({
						id = id,
						is_footnote = true,
					})
				)
			end

			local _node
			if not vim.tbl_isempty(_footnotes) then
				_node = NuiTree.Node(_line, _footnotes)
			else
				_node = NuiTree.Node(_line)
			end

			-- table.insert(node, _node)
			self.tree:add_node(_node)
		end
	end

	-- toggle node
	self.view:map("n", config.options.view.keymaps.toggle, function()
		local linenr = vim.api.nvim_win_get_cursor(self.view.winid)[1]
		local _node = self.tree:get_node(linenr)
		if _node:is_expanded() then
			_node:collapse()
		else
			_node:expand()
		end

		self.tree:render()
	end)
end

function Renderer:render()
	-- vim.api.nvim_buf_set_option(self.bufnr, "modifiable", true)
	-- vim.api.nvim_buf_set_lines(self.bufnr, 0, -1, false, {})
	self.tree:render()
end

return Renderer
