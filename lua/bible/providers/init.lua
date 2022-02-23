local config = require("bible.config")
local util = require("bible.util")
local log = require("bible.util.log")

local M = {}

M.providers = {}
M.options = {}

function M.get_provider(options)
  local sc = config.options.default_provider and config.options.default_provider or M.options.provider
  return require("bible.providers."..sc)
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

-- Interface for all added providers
-- Must implement these functions
function M:lookup_verse(cb, options)
  local provider = M.get_provider(options)

  local queries = util.splitStr(options.query, {sep = ";"})

  local ordered_keys = {}

  for k in pairs(queries) do
    table.insert(ordered_keys, k)
  end

  table.sort(ordered_keys)
  local verses = {}
  for i = 1, #ordered_keys do
    local k, v = ordered_keys[i], queries[ ordered_keys[i] ]
    options.query = v
    verses[v] = provider:lookup_verse(options)
    cb(verses[v], options)
  end
end

---@param options BibleOptions
function M:get(win, buf, cb, options)
  local name = options.mode
  local provider = M.providers[name]

  local queries = util.splitStr(options.query, {sep = ";"})
  local ordered_keys = {}

  for k in pairs(queries) do
    table.insert(ordered_keys, k)
  end

  table.sort(ordered_keys)
  local verses = {}
  for i = 1, #ordered_keys do
    local k, v = ordered_keys[i], queries[ ordered_keys[i] ]
    options.query = v
    verses[v] = provider:lookup_verse(options)
  end

  cb(verses, options)

end


return M
