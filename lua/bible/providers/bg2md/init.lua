local formatter = require("bible.providers.bg2md.formatter")
local util = require("bible.util")

local M = {}

-- default options
-- good for bible study
local defaults = {
  boldwords = true,
  x_copyright = true,
  x_headers = false,
  x_footnotes = false,
  newline = true,
  x_numbering = false,
  x_crossrefs = false,
  version = "NABRE",
}

M.options = {}


function M.setup(options)
  M.options = vim.tbl_deep_extend("force", {}, defaults, options or {})
end

function M.create_params(options)
  local out = {}
  for k, v in pairs(options) do
    local k_cleaned = k:gsub("x_", "")
    if v == true and k ~= "query" then
      table.insert(out, " --" .. k_cleaned)
    elseif k == "version" then
      table.insert(out, " --version " .. v)
    end
  end
  return table.concat(out)
end

function M:lookup_verse(query, provider_options, cb)
  provider_options = provider_options or {}
  local options = vim.tbl_extend("force", M.options, provider_options)
  local args = M.create_params(options)
  local bg2md_call = 'bg2md ' .. args .. " '" .. query .. "'"
  util.debug(bg2md_call)
  local result = vim.fn.systemlist(bg2md_call)
  local formatted
  if cb then
    formatted = cb(result)
  else
    formatted = formatter.bible_nvim(result)
  end
  return vim.tbl_extend("force", { result = formatted, name = query }, options)
end

return M
