local dev = require("hle.util.dev")
local config = require("bible.config")
local providers = require("bible.providers")
local View = require("bible.view")
local util = require("bible.util")


local Bible = {}

local function get_opts(...)
  local args = { ... }
  if vim.tbl_islist(args) and #args == 1 and type(args[1]) == "table" then
    args = args[1]
  end
  local opts = {}
  for key, value in pairs(args) do
    if type(key) == "number" then
      local k, v = value:match("^(.*)=(.*)$")
      if k then
        opts[k] = v
      elseif opts.mode then
        -- util.error("unknown option " .. value)
      else
        opts.mode = value
      end
    else
      opts[key] = value
    end
  end
  opts = opts or {}
  -- util.fix_mode(opts)
  config.options = opts
  return opts
end

function Bible.setup(options)
  -- local options = get_opts(...)
  -- local options = vim.tbl_extend("force", options, config.defaults)

  dev.unload_packages("bible")
  config.setup(options)
  providers.setup(config.options.providers)

  require("bible.commands.builtin")
  print("sourced bible")
end

local views = {}

-- local function is_open()
--   local view = views[vim.fn.bufname()]
--   return view and view:is_valid()
-- end

function Bible.open(query, provider_options)
  -- local opts = get_opts(...)
  require("bible.providers").get(query, provider_options, function(results)
    local view = View.create(config.options, query, views)
    view:update(results, { focus = false })
  end)
end

function Bible.close()
  util.debug("got to close")
  -- local view = views[vim.api.nvim_get_current_buf()]
  -- local buf_name = vim.fn.bufname()
  if view:is_open() then
    view:close()
  end
end

function Bible.yank()
  util.debug("got to yan")
  local view = views[vim.api.nvim_get_current_buf()]
  local item = view:current_item()
  -- if is_open() then
  --   view:close()
  -- end
end

function Bible.realistic_func()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_command("sbuffer " .. buf)
end

function Bible.action(action)
  util.debug("GOT HERE " .. action)
  local buf_name = vim.fn.bufname()
  local view = views[buf_name]
  -- if action == "toggle_mode" then
  --   if config.options.mode == "document_diagnostics" then
  --     config.options.mode = "workspace_diagnostics"
  --   elseif config.options.mode == "workspace_diagnostics" then
  --     config.options.mode = "document_diagnostics"
  --   end
  --   action = "refresh"
  -- end

  if view and action == "on_win_enter" then
    view:on_win_enter()
  end
  if not view:is_open() then
    return Bible
  end
  -- if action == "hover" then
  --   view:hover()
  -- end
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
    Bible.close()
  end
  if action == "open_folds" then
    Bible.refresh({ open_folds = true })
  end
  if action == "close_folds" then
    Bible.refresh({ close_folds = true })
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
  if action == "close" then
    view:close()
    views[buf_name] = nil
    return Bible
  end
  if action == "cancel" then
    view:switch_to_parent()
  end
  if action == "next" then
    view:next_item()
    return Bible
  end
  if action == "previous" then
    view:previous_item()
    return Bible
  end

  -- if action == "toggle_preview" then
  --   config.options.auto_preview = not config.options.auto_preview
  --   if not config.options.auto_preview then
  --     view:close_preview()
  --   else
  --     action = "preview"
  --   end
  -- end
  -- if action == "auto_preview" and config.options.auto_preview then
  --   action = "preview"
  -- end
  -- if action == "preview" then
  --   view:preview()
  -- end

  --util.debug("again...")

  if Bible[action] then
    Bible[action]()
  end
  return Bible
end

return Bible
