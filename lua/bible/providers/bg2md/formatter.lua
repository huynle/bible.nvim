local M = {}

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

function M.crossrefs_verses(text)
  local array = {}
  local possible = {
    "([%–%-%d%:]+)[%;%.%s]?", -- regular verses 5:2-4
    -- "(%a+)%s?([%–%-%d%:]+)", -- regular verses Dn 5:2-4
    "(%a+)%s?([%–%-%d%:,%s]+)[%;%.%s]?", -- verses Neh 3:1, 32
    "(%d[% ]%a+)%s?([%–%-%d%:]+)[%;%.%s]?", -- more complicated '1 Jn 5:2-4'
    "(%d[%s]%a+)%s?([%–%-%d%:]+)[%;%.%s]?", -- more complicated '1 Jn 5:2-4'
  }
  for _, pattern in pairs(possible) do
    for capture in string.gmatch(text, pattern) do
      table.insert(array, capture)
    end
  end
  return array
end

function M.captures(pattern_name, text)
  local ret = {}
  if not pattern_name then
    return {}
  end

  for key, pattern in pairs(M.patterns[pattern_name].captures) do
    if pattern == nil then
      ret[key] = nil
    elseif type(pattern) == "string" then
      ret[key] = string.match(text, pattern)
    elseif type(pattern) == "function" then
      ret[key] = pattern(text)
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
      query = "^# ([%w%d%s%:]+)%s",
      version = "%((.+)%)"
    },
  },
  chapter = {
    match = function(text)
      return string.match(text, "^## (.+)$")
    end,
    captures = {
      chapter = "^## ([%w%d%s]+)",
      footnotes = M.footnotes,
      crossrefs = M.crossrefs
    }
  },
  verses = {
    match = function(text)
      return string.match(text, "^###### (.+)$")
    end,
    captures = {
      verse = "^###### (.+)$",
      footnotes = M.footnotes,
      crossrefs = M.crossrefs
    }
  },
  footnotes = {
    match = function(text)
      return string.match(text, "^### (Footnotes)$")
    end,
    captures = {
      key = M.footnotes,
      verses = "%s([%d%:%-]+)%s",
      footnotes = "%s[%d%:%-]+%s(.+)$"
    }
  },
  crossrefs = {
    match = function(text)
      return string.match(text, "^### (Crossrefs)$")
    end,
    captures = {
      key = M.crossrefs,
      verses = M.crossrefs_verses
    }
  },

}

return M
