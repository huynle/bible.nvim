local M = {}

local defaults = {
  debug = true,
  -- default_provider = "bg2md",
  -- providers = {},
  display = true,
}

M.options = {}

function M.setup(options)
  M.options = vim.tbl_deep_extend("force", {}, defaults, options or {})
  -- M.apply_defaults_to_providers()
end

M.setup()

return M
