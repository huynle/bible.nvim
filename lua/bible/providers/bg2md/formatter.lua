local util = require("bible.util")

local M = {}


local function clean_line(line)
  -- strip ending spaces from line
  return line:gsub("%s+$", "")
end

function M.collect(result)
  local final = {
    query = {},
    chapter = {},
    verses = {},
    footnotes = {},
    crossrefs = {},
    version = "NABRE",
  }

  -- final = vim.tbl_extend("force", final, result)

  local pattern
  for _, line in ipairs(result) do
    pattern = M.get_pattern(line) or pattern
    if not util.isempty(line) then
      local captures = M.captures(pattern, line)
      -- create entry for pattern
      -- if not final[pattern] then
      --   final[pattern] = {}
      -- end

      if pattern and not util.istableempty(captures) then
        -- create entry for key
        -- if captures.key and not final[pattern][captures.key] then
        --   final[pattern][captures.key] = {}
        --   table.insert(final[pattern][captures.key], captures.value)
        --   table.insert(final[pattern][captures.key], captures.other)
        -- end
        table.insert(final[pattern], captures)
      end
    end
  end

  return final
end

function M.reorg(result)
  local keys = { "chapter", "verses" }
  return result
end

function M.bible_nvim(result)
  local collected = M.collect(result)
  return collected
end

function M.query(text)
  return string.match(text, "^# ([%w%d%s%:]+)%s")
end

function M.chapter(text)
  return string.match(text, "^## ([%w%d%s]+)")
end

function M.footnotes(text)
  local array = {}
  for capture in string.gmatch(text, "%[%^(%l+)%]") do
    table.insert(array, capture)
  end
  return array
end

function M.crossrefs(text)
  local array = {}
  for capture in string.gmatch(text, "%[%^(%u+)%]") do
    table.insert(array, capture)
  end
  return array
end

function M.crossrefs_verses(text, opts)
  -- [^B]: Neh 3:1, 32; 12:39.
  -- expected_return = { {
  --   book_name = "Neh",
  --   verses = { "3:1", "32" }
  -- },{
  --   verses = { "12:39" }
  -- }}
  -- 1. strip off the first 6 characters
  -- 2. split the rest of the text into items
  -- 3. loop through the items to get the verses
  opts = opts or {}
  local stripped = string.sub(text, 6)
  local items = util.splitStr(stripped, { sep = ";" })
  local ret = {}
  for _, item in pairs(items) do
    local out = M.get_verse_from_string(item, opts)
    if not util.istableempty(out) then
      table.insert(ret, out)
    end
  end
  return ret
end

function M.get_verse_from_string(text, opts)
  opts = opts or {}
  local ret = {
    book_name = opts.book_name,
    verses = {}
  }
  local verse_number_str = text
  -- more complicated '1 Jn 5:2-4, 5'
  local start_i, end_i
  start_i, end_i, ret.book_name = string.find(text, "(%d?[% %s]?%a+)")

  if start_i and end_i then
    verse_number_str = string.sub(text, end_i + 1)
  end

  for capture in string.gmatch(verse_number_str, "([%–%-%d%:]+)") do
    table.insert(ret.verses, capture)
  end

  if util.istableempty(ret.verses) then
    return {}
  end

  return ret
end

function M.captures(pattern_name, text)
  local ret = {}
  if not pattern_name then
    return {}
  end

  ret = M._captures(M.patterns[pattern_name].captures, text)
  return ret
end

-- traverse down a capture table
function M._captures(capture_patterns, text)
  local ret = {}
  for key, pattern in pairs(capture_patterns) do
    local val
    local results
    if pattern == nil then
      val = nil
    elseif type(pattern) == "string" then
      results = string.match(text, pattern)
      val = util.ternary(util.isempty(results), nil, results)
    elseif type(pattern) == "table" then
      if pattern.pattern then
        results = string.match(text, pattern.pattern)
        if pattern.callback then
          results = pattern.callback(results)
        end
        val = util.ternary(util.isempty(results), nil, results)
      else
        -- recursive pattern table
        local inside_pattern_result = M._captures(pattern, text)
        val = util.ternary(util.istableempty(inside_pattern_result), nil, inside_pattern_result)
      end
    elseif type(pattern) == "function" then
      results = pattern(text)
      val = util.ternary(util.istableempty(results), nil, results)
    end
    if val then
      ret[key] = val
    end
  end

  return ret
end

function M.get_pattern(text)
  for key, pattern in pairs(M.patterns) do
    if pattern.match(text) then
      return key
    end
  end
  return nil
end

M.patterns = {
  query = {
    -- extract out the content of the markdown headers
    match = function(text)
      return string.match(text, "^# (.+)$")
    end,
    captures = {
      id = "^# ([%w%d%s%:%-]+)%s",
      value = "%((.+)%)",
    },
  },
  chapter = {
    match = function(text)
      return string.match(text, "^## (.+)$")
    end,
    captures = {
      id = "^## %w+%s(%d+)",
      value = "^## ([%w%d%s]+)",
      other = {
        footnotes = M.footnotes,
        crossrefs = M.crossrefs
      }
    }
  },
  verses = {
    match = function(text)
      return string.match(text, "^###### (.+)$")
    end,
    captures = {
      value = {
        pattern = "^######%s%d+%s(.+)$",
        -- callback = clean_line
      },
      id = {
        pattern = "^######%s(%d+)%s",
        -- callback = tonumber
      },
      other = {
        footnotes = M.footnotes,
        crossrefs = M.crossrefs
      }
    }
  },
  footnotes = {
    match = function(text)
      return string.match(text, "^### (Footnotes)$")
    end,
    captures = {
      -- key = M.footnotes,
      id = "%[%^(%l+)%]",
      -- verses = "%s([%d%:%-]+)%s",
      value = "%s[%d%:%-%–]+%s(.+)$"
    }
  },
  crossrefs = {
    match = function(text)
      return string.match(text, "^### (Crossrefs)$")
    end,
    captures = {
      -- crossrefs = M.crossrefs,
      id = "%[%^(%u+)%]",
      -- value = "%[%^(%u+)%]",
      value = M.crossrefs_verses
    }
  },

}

return M
