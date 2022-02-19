local dev = require("hle.util.dev")
local config = require("bible.config")

local keymap_opts = { noremap = true, silent = true }

local M = {}
-- default options

function M.setup(bible_opts, ui_opts)
  dev.unload_packages("bible")

  config.options = vim.tbl_extend("force", config.defaults, ui_opts)
  
  local scraper = require("bible.scrapers."..config.options.scraper)
  scraper.options = vim.tbl_extend("force", scraper.defaults, bible_opts)

  require("bible.commands.builtin")
  print("sourced bible")
end

function M.enable_mapping()
  vim.api.nvim_set_keymap("v", "<leader>bb", ":'<,'>BibleLookupSelection {x_footnotes=true, x_crossrefs=true}<CR>", keymap_opts)
  vim.api.nvim_set_keymap("n", "<leader>bb", "<cmd>BibleLookupWORD {x_footnotes=true, x_crossrefs=true}<CR>", keymap_opts)
  -- bible study mode - enable all
  vim.api.nvim_set_keymap("n", "<leader>bs", "<cmd>BibleLookupWORD<CR>", keymap_opts)
  -- vietnamese version
  vim.api.nvim_set_keymap("n", "<leader>bfv", "<Cmd>BibleLookup { query = vim.fn.input('Search: ') , version='NVB'}<CR>", keymap_opts)
  vim.api.nvim_set_keymap("n", "<leader>bf", "<Cmd>BibleLookup { query = vim.fn.input('Search: ')}<CR>", keymap_opts)

  vim.api.nvim_set_keymap("n", "<leader>R", "<cmd>source ~/projects/bible.nvim/lua/bible/init.lua<CR>", keymap_opts)
end


M.setup({
  boldwords = true,
  x_copyright = true,
  x_headers = false,
  x_footnotes = false,
  newline = false,
  x_numbering = false,
  x_crossrefs = false,
  version = "NABRE",
},{
  display = true
})

M.enable_mapping()

return M
