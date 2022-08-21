local config = require("bible.config")
-- local provider = require("bible.providers")
local commands = require("bible.commands")
-- local actions = require("bible.actions")
local util = require("bible.util")
-- local View = require("bible.view")
local Bible = require("bible")

local keymap_opts = { noremap = true, silent = true }

commands.add("BibleLookupSelection", function(options)
  local selected_text = util.get_text_in_range(util.get_selected_range())
  assert(selected_text ~= nil, "No selected text")
  local query = vim.tbl_extend("force", { query = selected_text }, options or {})
  -- provider:lookup_verse(actions.display_verse, options)
  -- view = View.create(query, config.options)
  Bible.open(query)
  -- provider:get(query, view)
end, { needs_selection = true })

-- commands.add("BibleLookupWORD", function(options)
--   local selected_text = vim.call('expand', '<cWORD>')
--   local options = vim.tbl_extend("force", { query = selected_text }, options or {})
--   provider:lookup_verse(actions.display_verse, options)
-- end)

-- commands.add("BibleLookup", function(options)
--   provider:lookup_verse(actions.display_verse, options)
-- end)
--

-- function Bible.enable_mapping()
vim.api.nvim_set_keymap("v", "<leader>bb", ":'<,'>BibleLookupSelection {x_footnotes=true, x_crossrefs=true}<CR>", keymap_opts)
-- vim.api.nvim_set_keymap("n", "<leader>bb", "<cmd>BibleLookupWORD {x_footnotes=true, x_crossrefs=true}<CR>", keymap_opts)
-- -- bible study mode - enable all
-- -- vim.api.nvim_set_keymap("n", "<leader>bs", "<cmd>BibleLookupWORD { provider='bg2md' }<CR>", keymap_opts)
-- vim.api.nvim_set_keymap("n", "<leader>bs", "<cmd>BibleLookupWORD<CR>", keymap_opts)
-- -- vietnamese version
-- vim.api.nvim_set_keymap("n", "<leader>bv", "<Cmd>BibleLookup { query = vim.fn.input('Search: ') , version='NVB'}<CR>", keymap_opts)
-- vim.api.nvim_set_keymap("n", "<leader>bf", "<Cmd>BibleLookup { query = vim.fn.input('Search: ')}<CR>", keymap_opts)

-- vim.api.nvim_set_keymap("n", "<leader>R", "<cmd>source ~/.local/share/nvim/site/pack/packer/start/bible.nvim/lua/bible/init.lua<CR>", keymap_opts)
-- -- end
