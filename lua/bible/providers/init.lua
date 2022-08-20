local config = require("bible.config")
local util = require("bible.util")
local log = require("bible.util.log")

local M = {}

M.providers = {}
M.options = {}

function M.get_provider(options)
  local sc = config.options.default_provider and config.options.default_provider or M.options.provider
  return require("bible.providers." .. sc)
end

function M.setup(options)
  -- cycle throug each provider and setup its default options
  for provider_name, settings in pairs(options) do
    local provider
    local ok, mod = pcall(require, "bible.providers." .. provider_name)
    if ok then
      M.providers[provider_name] = mod
      provider = mod
    end

    if not provider then
      util.error(("invalid provider %q"):format(provider_name))
      return {}
    end
    provider.setup(settings)
  end
end

-- -- Interface for all added providers
-- -- Must implement these functions
-- function M:lookup_verse(cb, options)
--   local provider = M.get_provider(options)

--   local queries = util.splitStr(options.query, { sep = ";" })

--   local ordered_keys = {}

--   for k in pairs(queries) do
--     table.insert(ordered_keys, k)
--   end

--   table.sort(ordered_keys)
--   local verses = {}
--   for i = 1, #ordered_keys do
--     local k, v = ordered_keys[i], queries[ordered_keys[i]]
--     options.query = v
--     verses[v] = provider:lookup_verse(v, options)
--     cb(verses[v], options)
--   end
-- end

---@param options BibleOptions
-- function M:get(query_opts, view)
function M:get(query, cb, options)
  -- local options = vim.tbl_extend("force", config.options, options or {})

  -- local name = options.mode
  local provider = M.get_provider()

  -- local queries = util.splitStr(options.query, { sep = ";" })
  -- local verse = Verse:new()

  local ordered_keys = {}

  for k in pairs(query) do
    table.insert(ordered_keys, k)
  end

  table.sort(ordered_keys)
  local items = {}
  for i = 1, #ordered_keys do
    local k, v = ordered_keys[i], query[ordered_keys[i]]
    items[v] = provider:lookup_verse(v, options)
    -- view:render(verse:render(v))
  end

  cb(items)
end

function M:group(items)
  -- grouping -- maybe for chapter
  local keys = {}
  local keyid = 0
  local groups = {}
  -- for _, item in ipairs(items) do
  for _, item in pairs(items) do
    -- if groups[item.chapter] == nil then
    --   groups[item.chapter] = { book = item.chapter, items = {} }
    --   keys[item.chapter] = keyid
    --   keyid = keyid + 1
    -- end
    -- table.insert(groups[item.chapter].items, item)

    if groups[item.name] == nil then
      groups[item.name] = { name = item.name, items = {} }
      keys[item.name] = keyid
      keyid = keyid + 1
    end
    table.insert(groups[item.name].items, item)

  end

  local ret = {}
  for _, group in pairs(groups) do
    table.insert(ret, group)
  end
  table.sort(ret, function(a, b)
    return keys[a.name] < keys[b.name]
  end)
  return ret
end

return M
