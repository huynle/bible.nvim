---@class Verse
---@field lines string[]
---@field hl Highlight[]
---@field lineNr number
---@field current string
local Verse = {}
Verse.__index = Verse

function Verse:new()
  local this = { lines = {}, hl = {}, lineNr = 0, current = "" }
  setmetatable(this, self)
  return this
end

function Verse:nl()
  table.insert(self.lines, self.current)
  self.current = ""
  self.lineNr = self.lineNr + 1
end

function Verse:render(str, group, opts)
  -- clean up the string for us
  for k, v in ipairs(str) do
    if str[k] then
      -- str[k] = str[k]:gsub("[\n]", " ")
    end
  end

  if type(opts) == "string" then
    opts = { append = opts }
  end
  opts = opts or {}

  if group then
    if opts.exact ~= true then
      group = "Bible" .. group
    end
    local from = string.len(self.current)
    ---@class Highlight
    local hl
    hl = {
      line = self.lineNr,
      from = from,
      to = from + string.len(str),
      group = group,
    }
    table.insert(self.hl, hl)
  end
  -- creating a full verse for now
  local str_concat = table.concat(str, "")
  self.current = self.current .. str_concat
  if opts.append then
    self.current = self.current .. opts.append
  end
  if opts.nl then
    self:nl()
  end
end

return Verse
