local M = {}

-- default options
-- good for bible study
local defaults = {
  boldwords = true,
  x_copyright = true,
  x_headers = false,
  x_footnotes = false,
  newline = false,
  x_numbering = false,
  x_crossrefs = false,
  version = "NABRE",
  query = ""
}

M.options = {}


function M.setup(options)
  M.options = vim.tbl_deep_extend("force", {}, defaults, options or {})
end

local function create_params(options)
  local out = {}
  for k, v in pairs(options) do
    local k_cleaned = k:gsub("x_", "")
    if v == true and k ~= "query" then
      table.insert(out, " --"..k_cleaned)
    elseif k == "version" then
      table.insert(out, " --version "..v)
    end
  end
  return table.concat(out)
end

local function clean_line(line)
  -- strip ending spaces from line
  return line:gsub("%s+$", "")
end

function M:lookup_verse(cb, options)
  local options = vim.tbl_extend("force", defaults, options)
  local args = create_params(options)
  local result = vim.fn.systemlist('bg2md '..args.." '"..options.query.."'")

  local cleaned = {}
  for _, line in ipairs(result) do
    -- assert( not string.find(string.lower(line), ".*error.*"), "Could not find verse "..line)
    assert( not string.find(line, "Error:"), "Could not find verse "..line)
    cleaned[#cleaned+1] = clean_line(line)
  end

  cb(cleaned, options)
end

return M
