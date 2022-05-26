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
  vim.api.nvim_set_keymap("n", "<leader>bv", "<Cmd>BibleLookup { query = vim.fn.input('Search: ') , version='NVB'}<CR>", keymap_opts)
  vim.api.nvim_set_keymap("n", "<leader>bf", "<Cmd>BibleLookup { query = vim.fn.input('Search: ')}<CR>", keymap_opts)

  vim.api.nvim_set_keymap("n", "<leader>R", "<cmd>source ~/.local/share/nvim/site/pack/packer/start/bible.nvim/lua/bible/init.lua<CR>", keymap_opts)
end

local view

local function is_open()
  return view and view:is_valid()
end

function M.action(action)
  if action == "toggle_mode" then
    if config.options.mode == "document_diagnostics" then
      config.options.mode = "workspace_diagnostics"
    elseif config.options.mode == "workspace_diagnostics" then
      config.options.mode = "document_diagnostics"
    end
    action = "refresh"
  end

  if view and action == "on_win_enter" then
    view:on_win_enter()
  end
  if not is_open() then
    return M
  end
  if action == "hover" then
    view:hover()
  end
  if action == "jump" then
    view:jump()
  elseif action == "open_split" then
    view:jump({ precmd = "split" })
  elseif action == "open_vsplit" then
    view:jump({ precmd = "vsplit" })
  elseif action == "open_tab" then
    view:jump({ precmd = "tabe" })
  end
  if action == "jump_close" then
    view:jump()
    M.close()
  end
  if action == "open_folds" then
    M.refresh({ open_folds = true })
  end
  if action == "close_folds" then
    M.refresh({ close_folds = true })
  end
  if action == "toggle_fold" then
    view:toggle_fold()
  end
  if action == "on_enter" then
    view:on_enter()
  end
  if action == "on_leave" then
    view:on_leave()
  end
  if action == "cancel" then
    view:switch_to_parent()
  end
  if action == "next" then
    view:next_item()
    return M
  end
  if action == "previous" then
    view:previous_item()
    return M
  end

  if action == "toggle_preview" then
    config.options.auto_preview = not config.options.auto_preview
    if not config.options.auto_preview then
      view:close_preview()
    else
      action = "preview"
    end
  end
  if action == "auto_preview" and config.options.auto_preview then
    action = "preview"
  end
  if action == "preview" then
    view:preview()
  end

  if M[action] then
    M[action]()
  end
  return M
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
      version = "NET",
    }
  }
})

M.enable_mapping()

return M
