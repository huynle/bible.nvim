local M = {}

local defaults = {
  default_provider = "bg2md",
  providers = {},
  display = true,
}

M.options = {}

function M.setup(options)
  M.options = vim.tbl_deep_extend("force", {}, defaults, options or {})
  -- M.apply_defaults_to_providers()
end

-- function M.apply_defaults_to_providers()
--   -- cycle throug each provider and setup its default options
--   for provider_name, settings in pairs(M.options.providers) do
--     local provider = require("bible.providers."..provider_name)
--     provider.options = vim.tbl_extend("force", provider.defaults, settings)
--   end
-- end

M.setup()

return M
