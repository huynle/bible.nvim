local config = require("bible.config")

local M = {}

-- default options
M.defaults = {
  provider = "bg2md"
}

M.options = {}

function M.get_provider(options)
  local sc = config.options.default_provider and config.options.default_provider or M.options.provider
  return require("bible.providers."..sc)
end

function M.setup(options)
  -- cycle throug each provider and setup its default options
  for provider_name, settings in pairs(options) do
    local provider = require("bible.providers."..provider_name)
    provider.setup(options.bg2md)
  end
end

-- Interface for all added providers
-- Must implement these functions
function M:lookup_verse(cb, options)
  local provider = M.get_provider(options)
  provider:lookup_verse(cb, options)
end

return M
