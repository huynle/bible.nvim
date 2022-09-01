local mock = require('luassert.mock')
local stub = require('luassert.stub')
local providers = require "bible.providers"
local bg2md = require "bible.providers.bg2md"
local bg2md_parser = require "bible.providers.bg2md.formatter"
local util = require("bible.util")

local eq = assert.are.same
bg2md.setup({
  boldwords = true,
  x_copyright = true,
  x_headers = false,
  x_footnotes = false,
  newline = true,
  x_numbering = false,
  x_crossrefs = false,
  version = "NABRE",
})

describe("bg2md", function()
  it("split", function()
    local final = {
      query = {},
      chapter = {},
      verses = {},
      footnotes = {},
      crossrefs = {}

    }

    local out = bg2md:lookup_verse("john5:1-5", {}, function(result)

      local pattern
      for i, line in ipairs(result.verses) do
        pattern = bg2md_parser.get_pattern(line) or pattern
        local captures = bg2md_parser.captures(pattern, line)
        if pattern and captures then
          table.insert(final[pattern], captures)
        end
      end
      Print(final)
    end)
  end)
end)
