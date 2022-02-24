local util = require("bible.util")
local providers = require("bible.providers")
local config = require("bible.config")
local Verse = require("bible.verse")

local renderer = {}

---@param view BibleView
---@param verse Verse
---@param items Item[]
---@param filename string
function renderer.render_file(view, verse, filename, items)
  view.items[verse.lineNr + 1] = { filename = filename, is_file = true }

  if view.group == true then
    local count = util.count(items)

    verse:render(" ")

    if folds.is_folded(filename) then
      verse:render(config.options.fold_closed, "FoldIcon", " ")
    else
      verse:render(config.options.fold_open, "FoldIcon", " ")
    end

    if config.options.icons then
      local icon, icon_hl = get_icon(filename)
      verse:render(icon, icon_hl, { exact = true, append = " " })
    end

    verse:render(vim.fn.fnamemodify(filename, ":p:."), "File", " ")
    verse:render(" " .. count .. " ", "Count")
    verse:nl()
  end

  if not folds.is_folded(filename) then
    renderer.render_diagnostics(view, verse, items)
  end
end

---@param view BibleView
function renderer.render(view, query, opts)
  opts = opts or {}
  local buf = vim.api.nvim_win_get_buf(view.parent)
  providers:get(view.parent, buf, function(verses)
    -- FIXME: working on group!
    -- local grouped = providers:group(verses)
    -- local count = util.count(grouped)

    -- check for auto close
    if opts.auto and config.options.auto_close then
      if util.tablelength(verses) == 0 then
        view:close()
        return
      end
    end

    if util.tablelength(verses) == 0 then
      util.warn("no results")
    end

    -- dump(verses)
    local verse = Verse:new()
    view.items = {}

    if config.options.padding then
      verse:nl()
    end

    for k, v in pairs(verses) do
      verse:render(k)
      verse:nl()
    end

    view:render(verse)

    -- if config.options.padding then
    --   verse:nl()
    -- end

    -- view:render(verse)
    -- if opts.focus then
    --   view:focus()
    -- end

  end, query)
end


return renderer
