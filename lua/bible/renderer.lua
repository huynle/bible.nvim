local util = require("bible.util")
local providers = require("bible.providers")
local config = require("bible.config")
local Text = require("bible.text")

local renderer = {}

---@param view BibleView
---@param text Text
---@param items Item[]
---@param filename string
function renderer.render_file(view, text, filename, items)
  view.items[text.lineNr + 1] = { filename = filename, is_file = true }

  if view.group == true then
    local count = util.count(items)

    text:render(" ")

    if folds.is_folded(filename) then
      text:render(config.options.fold_closed, "FoldIcon", " ")
    else
      text:render(config.options.fold_open, "FoldIcon", " ")
    end

    if config.options.icons then
      local icon, icon_hl = get_icon(filename)
      text:render(icon, icon_hl, { exact = true, append = " " })
    end

    text:render(vim.fn.fnamemodify(filename, ":p:."), "File", " ")
    text:render(" " .. count .. " ", "Count")
    text:nl()
  end

  if not folds.is_folded(filename) then
    renderer.render_diagnostics(view, text, items)
  end
end

---@param view BibleView
function renderer.render(view, results, opts)
  opts = opts or {}
  local buf = vim.api.nvim_win_get_buf(view.parent)


  local grouped = providers:group(results, view.group)
  local count = util.tablelength(grouped)

  -- check for auto close
  if opts.auto and config.options.auto_close then
    if util.tablelength(results) == 0 then
      if count == 0 then
        view:close()
        return
      end
    end
  end

  if util.tablelength(results) == 0 then
    util.warn("no results")
  end

  -- dump(texts)
  local text = Text:new()
  view.items = {}

  if config.options.padding then
    text:nl()
  end

  for k, v in pairs(grouped) do
    text:render(v.items, v.name)
    text:nl()
  end

  view:render(text)

  -- if config.options.padding then
  --   text:nl()
  -- end

  -- view:render(text)
  if opts.focus then
    view:focus()
  end



  -- -- # TEXT INJECTION HERE
  -- providers:get(function(texts)
  --   -- FIXME: working on group!
  --   local grouped = providers:group(texts)
  --   local count = util.tablelength(grouped)

  --   -- check for auto close
  --   if opts.auto and config.options.auto_close then
  --     if util.tablelength(texts) == 0 then
  --       if count == 0 then
  --         view:close()
  --         return
  --       end
  --     end
  --   end

  --   if util.tablelength(texts) == 0 then
  --     util.warn("no results")
  --   end

  --   -- dump(texts)
  --   local text = Text:new()
  --   view.items = {}

  --   if config.options.padding then
  --     text:nl()
  --   end

  --   for k, v in pairs(texts) do
  --     text:render(v.value)
  --     text:nl()
  --   end

  --   view:render(text)

  --   -- if config.options.padding then
  --   --   text:nl()
  --   -- end

  --   -- view:render(text)
  --   if opts.focus then
  --     view:focus()
  --   end

  -- end, config.options)
end

return renderer
