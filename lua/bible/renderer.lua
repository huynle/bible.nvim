local config = require("bible.config")
local NuiTree = require("nui.tree")
local NuiLine = require("nui.line")
local utils = require("bible.utils")
local Object = require("bible.common.object")

local Renderer = Object("Renderer")

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
					-- line:append((node.versenum or "") .. "\t\t" .. (node.text or ""))
					line:append(string.format("%-4s%s", (node.versenum or ""), (node.text or "")))
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

--- Prepares the tree structure for rendering Bible verses with support for multiline text.
--- This function creates a tree structure where each verse can have multiple lines of text,
--- with verse numbers shown only on the first line. It also handles footnotes and header display.
---
--- @param opts table Optional settings that override default options
function Renderer:prepare_tree(opts)
	opts = opts or {}
	opts = vim.tbl_extend("force", self.lookup.opts, opts)

	-- Add header if specified
	if opts.show_header then
		local _surround = {
			opts.show_header.surround,
			opts.versions[1],
			opts.query,
			opts.show_header.surround,
		}

		local _header = NuiTree.Node({ text = table.concat(_surround, " ") })
		self.tree:add_node(_header)
	end

	-- Process verses
	for _, key in ipairs(utils.sort_verse(self.lookup.book)) do
		for ith, partial_verse in ipairs(self.lookup.book[key]) do
			-- Handle multiline text
			local text_lines = partial_verse.text
			if type(text_lines) == "string" then
				text_lines = { text_lines } -- Convert single string to table
			end

			-- Create nodes for each line of text
			for i, line in ipairs(text_lines) do
				local _line = {
					text = line,
					-- Only show verse number for the first line
					versenum = (i == 1) and partial_verse.versenum or "",
					is_verse = true,
				}

				-- Process footnotes (only for the first line)
				local _footnotes = {}
				if i == 1 then
					for tag, id in pairs(partial_verse.footnotes) do
						table.insert(
							_footnotes,
							NuiTree.Node({
								id = id.id or id,
								is_footnote = true,
							})
						)
					end
				end

				-- Create node with or without footnotes
				local _node
				if not vim.tbl_isempty(_footnotes) then
					_node = NuiTree.Node(_line, _footnotes)
				else
					_node = NuiTree.Node(_line)
				end

				self.tree:add_node(_node)
			end
		end
	end

	-- Set up toggle node functionality
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
