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

---@param options BibleOptions
-- function M:get(query_opts, view)
function M.get(query, provider_options, cb)
  local provider = M.get_provider()
  provider.setup(provider_options)

  local queries = util.splitStr(query, { sep = ";" })
  local ordered_keys = {}

  for k in pairs(queries) do
    table.insert(ordered_keys, k)
  end

  table.sort(ordered_keys)
  local items = {}
  for i = 1, #ordered_keys do
    local k, v = ordered_keys[i], queries[ordered_keys[i]]
    -- items[v] = provider:lookup_verse(v, provider_options)
    table.insert(items, provider:lookup_verse(v, provider_options))
    -- view:render(verse:render(v))
  end
  -- local results = { [query] = items }

  cb(items)
end

-- expect list of group by options
function M:group_by(items, opts)
  --FIXME: expand this later
  local grouped
  for i, group_by in pairs(opts.group_by) do
    grouped = self:group(items, group_by)
  end
  return grouped
end

function M:group_og(items, group_by)
  --- STOPPED HERE
  -- grouping -- maybe for chapter
  local keys = {}
  local keyid = 0
  local groups = {}
  for _, item in pairs(items) do
    if groups[group_by] == nil then
      groups[group_by] = { name = group_by, items = {} }
      keys[group_by] = keyid
      keyid = keyid + 1
    end
    table.insert(groups[group_by].items, item)
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

function M:group(items, group_by)
  --- STOPPED HERE
  -- grouping -- maybe for chapter
  local keys = {}
  local keyid = 0
  local groups = {}
  for _, item in pairs(items) do
    local group_name = item[group_by] or "None"
    -- create group in groups and key to track group
    if groups[group_name] == nil then
      groups[group_name] = { name = group_name, items = {} }
      keys[group_name] = keyid
      keyid = keyid + 1
    end
    table.insert(groups[group_name].items, item)
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
