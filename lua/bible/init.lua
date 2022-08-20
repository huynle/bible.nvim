local dev = require("hle.util.dev")
local config = require("bible.config")
local providers = require("bible.providers")
local View = require("bible.view")


local Bible = {}

function Bible.setup(options)
  dev.unload_packages("bible")
  config.setup(options)
  providers.setup(options.providers)

  -- require("bible.commands.builtin")
  print("sourced bible")
end

local view

local function is_open()
  return view and view:is_valid()
end

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
        util.error("unknown option " .. value)
      else
        opts.mode = value
      end
    else
      opts[key] = value
    end
  end
  opts = opts or {}
  util.fix_mode(opts)
  config.options.cmd_options = opts
  return opts
end

function Bible.open(query, ...)
  local opts = get_opts(...)
  if opts.mode and (opts.mode ~= config.options.mode) then
    config.options.mode = opts.mode
  end
  opts.focus = true
  require("bible.providers").get(query, function(results)
    view = View.create(opts)
    view:update(results)
  end, config.options)
end

function Bible.close()
  Print("got to close")
  if is_open() then
    view:close()
  end
end

function Bible.action(action)
  Print("GOT HERE " .. action)
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
  if not is_open() then
    return Bible
  end
  -- if action == "hover" then
  --   view:hover()
  -- end
  -- if action == "jump" then
  --   view:jump()
  -- elseif action == "open_split" then
  --   view:jump({ precmd = "split" })
  -- elseif action == "open_vsplit" then
  --   view:jump({ precmd = "vsplit" })
  -- elseif action == "open_tab" then
  --   view:jump({ precmd = "tabe" })
  -- end
  -- if action == "jump_close" then
  --   view:jump()
  --   Bible.close()
  -- end
  -- if action == "open_folds" then
  --   Bible.refresh({ open_folds = true })
  -- end
  -- if action == "close_folds" then
  --   Bible.refresh({ close_folds = true })
  -- end
  -- if action == "toggle_fold" then
  --   view:toggle_fold()
  -- end
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

  -- Print("again...")

  if Bible[action] then
    -- Print("ASDF")
    Bible[action]()
  end
  return Bible
end

Bible.setup({
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


return Bible
