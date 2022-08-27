local util = require("bible.util")
local providers = require("bible.providers")
local config = require("bible.config")
local Text = require("bible.text")
local folds = require("bible.folds")

local renderer = {}

local signs = {}

local function get_icon(file)
  local ok, icons = pcall(require, "nvim-web-devicons")
  if not ok then
    util.warn(
      "'nvim-web-devicons' is not installed. Install it, or set icons=false in your configuration to disable this message"
    )
    return ""
  end
  local fname = vim.fn.fnamemodify(file, ":t")
  local ext = vim.fn.fnamemodify(file, ":e")
  return icons.get_icon(fname, ext, { default = true })
end

local function update_signs()
  signs = config.options.signs
  if config.options.use_diagnostic_signs then
    local lsp_signs = require("trouble.providers.diagnostic").get_signs()
    signs = vim.tbl_deep_extend("force", {}, signs, lsp_signs)
  end
end

---@param view BibleView
---@param text Text
---@param items Item[]
---@param filename string
function renderer.render_group(view, text, name, items)
  view.items[text.lineNr + 1] = { name = name, is_grouped = true }

  if view.group.enabled == true then
    local count = util.count(items)

    text:render(" ")

    if folds.is_folded(name) then
      text:render(config.options.fold_closed, "FoldIcon", " ")
    else
      text:render(config.options.fold_open, "FoldIcon", " ")
    end

    if config.options.icons then
      local icon, icon_hl = get_icon(name)
      text:render(icon, icon_hl, { exact = true, append = " " })
    end

    text:render(name, " ")
    text:render(" " .. count .. " ", "Count")
    text:nl()
  end

  if not folds.is_folded(name) then
    renderer.render_verse(view, text, items)
  end
end

---@param view BibleView
function renderer.render(view, results, opts)
  opts = opts or {}
  local buf = vim.api.nvim_win_get_buf(view.parent)
  local grouped = providers:group_by(results, view.group)
  local count = util.count(grouped)

  -- check for auto close
  if opts.auto and config.options.auto_close then
    if util.count(results) == 0 then
      if count == 0 then
        view:close()
        return
      end
    end
  end

  if util.count(results) == 0 then
    util.warn("no results")
  end

  -- dump(texts)
  local text = Text:new()
  view.items = {}

  if config.options.padding then
    text:nl()
  end

  -- render groups
  for _, group in ipairs(grouped) do
    if opts.open_folds then
      folds.open(group.name)
    end
    if opts.close_folds then
      folds.close(group.name)
    end
    renderer.render_group(view, text, group.name, group.items)
  end


  view:render(text)
  if opts.focus then
    view:focus()
  end
end

---@param view TroubleView
---@param text Text
---@param items Item[]
function renderer.render_verse(view, text, items)
  for _, item in ipairs(items) do
    view.items[text.lineNr + 1] = item

    -- local sign = diag.sign or signs[string.lower(diag.type)]
    -- if not sign then
    --   sign = diag.type
    -- end

    local indent = "     "
    if config.options.indent_lines then
      indent = " │   "
    end

    -- local sign_hl = diag.sign_hl or ("TroubleSign" .. diag.type)

    text:render(indent, "Indent")
    -- text:render(sign .. "  ", sign_hl, { exact = true })
    -- text:render(diag.text, "Text" .. diag.type, " ")
    text:render(item.value)

    -- text:render(diag.type, diag.type, " ")

    if item.commentary then
      text:nl()
      text:render(indent, "Indent")
      text:render(item.commentary, "Commentary")
    end

    text:render(" ")

    -- text:render("[" .. diag.lnum .. ", " .. diag.col .. "]", "Location")
    text:nl()
  end
end

return renderer
