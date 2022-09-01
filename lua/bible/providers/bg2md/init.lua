local parser = require("bible.providers.bg2md.formatter")

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
      table.insert(out, " --" .. k_cleaned)
    elseif k == "version" then
      table.insert(out, " --version " .. v)
    end
  end
  return table.concat(out)
end

local function clean_line(line)
  -- strip ending spaces from line
  return line:gsub("%s+$", "")
end

local function break_verse(line)
  local verses = {}
  if line ~= "" then
    for verse_n, verse in string.find(line, "(%d+) (%w+)") do
      verses[verse_n] = verse
    end
  end
  return verses
end

function M:format(result)
  local final = {
    query = {},
    chapter = {},
    verses = {},
    footnotes = {},
    crossrefs = {},
    version = ""
  }
  local pattern
  for _, line in ipairs(result.verses) do
    pattern = parser.get_pattern(line) or pattern
    local captures = parser.captures(pattern, line)
    if pattern and captures then
      table.insert(final[pattern], captures)
    end
  end
  final.version = final["query"]["version"]
  -- Print(final)
  return final
end

function M:lookup_verse(query, provider_options, cb)
  provider_options = provider_options or {}
  local options = vim.tbl_extend("force", M.options, provider_options)
  local args = create_params(options)
  local result = vim.fn.systemlist('bg2md ' .. args .. " '" .. query .. "'")
  -- local cleaned = {}
  -- local verses = {}

  -- local final_result = {
  --   name = query,
  --   -- verses = { table.concat(result, " ") },
  --   verses = result,
  --   commentary = { "Go look at Gen1", "some thing with John3:16" },
  --   -- TESTING = {
  --   --   ANOTHER1 = { "OTHER comments1", "some OTHER comments 2" },
  --   --   -- ANOTHER2 = { "OTHER comments1", "some OTHER comments 2" },
  --   -- },
  --   -- value = table.concat(result, " "),
  --   -- value = result,
  --   version = options.version,
  -- }

  -- local final_result = {
  --   book = {
  --     name = {},
  --     value = {},
  --     commentary = {},
  --     chapter = {
  --       name = {},
  --       value = {},
  --       commentary = {},
  --       verse = {
  --         name = {},
  --         value = result,
  --         commentary = {}
  --       }
  --     },
  --   }
  -- }

  --   local result_map = {
  --     empty = 0,
  --     verse = "%s+\\d+",
  --     commentary = 2,
  --   }

  --   local verse = {
  --     version = "",
  --     item = "",
  --     commentary = "",
  --     crossref = ""
  --   }

  --   local book = {
  --     chapter = {},
  --   }

  -- for _, line in ipairs(result) do
  --   assert(not string.find(line, "Error:"), "Could not find verse " .. line .. " CHANGE YOUR VERSION to see")
  --   cleaned[#cleaned + 1] = clean_line(line)
  --   verses[#verses + 1] = break_verse(line)
  -- end

  -- if cb then
  --   return cb(final_result)
  -- else
  return M:format(result)
  -- end
end

return M
