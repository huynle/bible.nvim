local dev = require("hle.util.dev")
local config = require("bible.config")
local providers = require("bible.providers")

local keymap_opts = { noremap = true, silent = true }

local M = {}

function M.setup(options)
  dev.unload_packages("bible")
  config.setup(options)
  providers.setup(options.providers)

  require("bible.commands.builtin")
  print("sourced bible")
end


function M.enable_mapping()
  vim.api.nvim_set_keymap("v", "<leader>bb", ":'<,'>BibleLookupSelection {x_footnotes=true, x_crossrefs=true}<CR>", keymap_opts)
  vim.api.nvim_set_keymap("n", "<leader>bb", "<cmd>BibleLookupWORD {x_footnotes=true, x_crossrefs=true}<CR>", keymap_opts)
  -- bible study mode - enable all
  -- vim.api.nvim_set_keymap("n", "<leader>bs", "<cmd>BibleLookupWORD { provider='bg2md' }<CR>", keymap_opts)
  vim.api.nvim_set_keymap("n", "<leader>bs", "<cmd>BibleLookupWORD<CR>", keymap_opts)
  -- vietnamese version
  vim.api.nvim_set_keymap("n", "<leader>bfv", "<Cmd>BibleLookup { query = vim.fn.input('Search: ') , version='NVB'}<CR>", keymap_opts)
  vim.api.nvim_set_keymap("n", "<leader>bf", "<Cmd>BibleLookup { query = vim.fn.input('Search: ')}<CR>", keymap_opts)

  vim.api.nvim_set_keymap("n", "<leader>R", "<cmd>source ~/projects/bible.nvim/lua/bible/init.lua<CR>", keymap_opts)
end


M.setup({
  default_provider = "bg2mdasdf",
  providers = {
    bg2md = {
      boldwords = true,
      x_copyright = true,
      x_headers = false,
      x_footnotes = false,
      newline = false,
      x_numbering = false,
      x_crossrefs = false,
      version = "NABRE",
    }
  }
})

M.enable_mapping()

return M
