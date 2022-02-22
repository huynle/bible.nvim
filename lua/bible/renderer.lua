local util = require("trouble.util")

local renderer = {}

---@param view TroubleView
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

---@param view TroubleView
function renderer.render(view, opts)
  opts = opts or {}
  local buf = vim.api.nvim_win_get_buf(view.parent)
  providers.get(view.parent, buf, function(items)
    local grouped = providers.group(items)
    local count = util.count(grouped)

    -- check for auto close
    if opts.auto and config.options.auto_close then
      if count == 0 then
        view:close()
        return
      end
    end

    if #items == 0 then
      util.warn("no results")
    end

    -- Update lsp signs
    update_signs()

    local text = Text:new()
    view.items = {}

    if config.options.padding then
      text:nl()
    end

    -- render file groups
    for _, group in ipairs(grouped) do
      if opts.open_folds then
        folds.open(group.filename)
      end
      if opts.close_folds then
        folds.close(group.filename)
      end
      renderer.render_file(view, text, group.filename, group.items)
    end

    view:render(text)
    if opts.focus then
      view:focus()
    end
  end, config.options)
end


return renderer
