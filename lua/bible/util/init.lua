local config = require("bible.config")

local M = {}

---Finds the root directory of the notebook of the given path
--
---@param notebook_path string
---@return string? root
function M.notebook_root(notebook_path)
  return require("zk.root_pattern_util").root_pattern(".zk")(notebook_path)
end

---Try to resolve a notebook path by checking the following locations in that order
---1. current buffer path
---2. current working directory
---3. `$ZK_NOTEBOOK_DIR` environment variable
---
---Note that the path will not necessarily be the notebook root.
--
---@param bufnr number?
---@return string? path inside a notebook
function M.resolve_notebook_path(bufnr)
  local path = vim.api.nvim_buf_get_name(bufnr)
  local cwd = vim.fn.getcwd(0)
  -- if the buffer has no name (i.e. it is empty), set the current working directory as it's path
  if path == "" then
    path = cwd
  end
  if not M.notebook_root(path) then
    if not M.notebook_root(cwd) then
      -- if neither the buffer nor the cwd belong to a notebook, use $ZK_NOTEBOOK_DIR as fallback if available
      if vim.env.ZK_NOTEBOOK_DIR then
        path = vim.env.ZK_NOTEBOOK_DIR
      end
    else
      -- the buffer doesn't belong to a notebook, but the cwd does!
      path = cwd
    end
  end
  -- at this point, the buffer either belongs to a notebook, or everything else failed
  return path
end

---Makes an LSP location object from the last selection in the current buffer.
--
---@return table LSP location object
---@see https://microsoft.github.io/language-server-protocol/specifications/specification-current/#location
function M.get_lsp_location_from_selection()
  local params = vim.lsp.util.make_given_range_params()
  params.uri = params.textDocument.uri
  params.textDocument = nil
  params.range = M.get_selected_range() -- workaround for neovim 0.6.1 bug (https://github.com/mickael-menu/zk-nvim/issues/19)
  return params
end

---Gets the text in the given range of the current buffer.
---Needed until https://github.com/neovim/neovim/pull/13896 is merged.
--
---@param range table contains {start} and {end} tables with {line} (0-indexed, end inclusive) and {character} (0-indexed, end exclusive) values
---@return string? text in range
function M.get_text_in_range(range)
  local A = range["start"]
  local B = range["end"]

  local lines = vim.api.nvim_buf_get_lines(0, A.line, B.line + 1, true)
  if vim.tbl_isempty(lines) then
    return nil
  end
  local MAX_STRING_SUB_INDEX = 2 ^ 31 - 1 -- LuaJIT only supports 32bit integers for `string.sub` (in block selection B.character is 2^31)
  lines[#lines] = string.sub(lines[#lines], 1, math.min(B.character, MAX_STRING_SUB_INDEX))
  lines[1] = string.sub(lines[1], math.min(A.character + 1, MAX_STRING_SUB_INDEX))
  return table.concat(lines, "\n")
end

---Gets the most recently selected range of the current buffer.
---That is the text between the '<,'> marks.
---Note that these marks are only updated *after* leaving the visual mode.
--
---@return table selected range, contains {start} and {end} tables with {line} (0-indexed, end inclusive) and {character} (0-indexed, end exclusive) values
function M.get_selected_range()
  -- code adjusted from `vim.lsp.util.make_given_range_params`
  -- we don't want to use character encoding offsets here

  local A = vim.api.nvim_buf_get_mark(0, "<")
  local B = vim.api.nvim_buf_get_mark(0, ">")

  -- convert to 0-index
  A[1] = A[1] - 1
  B[1] = B[1] - 1
  if vim.o.selection ~= "exclusive" then
    B[2] = B[2] + 1
  end
  return {
    start = { line = A[1], character = A[2] },
    ["end"] = { line = B[1], character = B[2] },
  }
end

function M.warn(msg)
  vim.notify(msg, vim.log.levels.WARN, { title = "Trouble" })
end

function M.error(msg)
  vim.notify(msg, vim.log.levels.ERROR, { title = "Trouble" })
end

function M.debug(msg)
  if config.debug then
    vim.notify(msg, vim.log.levels.DEBUG, { title = "Trouble" })
  end
end

function M.throttle(ms, fn)
  local timer = vim.loop.new_timer()
  local running = false
  return function(...)
    if not running then
      local argv = { ... }
      local argc = select("#", ...)

      timer:start(ms, 0, function()
        running = false
        pcall(vim.schedule_wrap(fn), unpack(argv, 1, argc))
      end)
      running = true
    end
  end
end

function M.splitStr(inputstr, opts)
  opts = vim.tbl_deep_extend("force", {
    sep = "%s",
    clean_before = true,
    clean_after = true,
  }, opts)
  -- return an ordered table, or key and its index
  local t = {}
  for str in string.gmatch(inputstr, "([^" .. opts.sep .. "]+)") do
    str = M.cleanStr(str, opts)
    if str ~= "" then
      t[#t + 1] = str
    end
  end
  return t
end

function M.cleanStr(line, opts)
  opts = vim.tbl_deep_extend("force", {
    clean_before = false,
    clean_after = true,
  }, opts)

  if opts.clean_before then
    line = line:gsub("^%s+", "")
  end

  if opts.clean_after then
    line = line:gsub("%s+$", "")
  end
  -- strip ending spaces from line
  return line
end

function M.count(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

return M
