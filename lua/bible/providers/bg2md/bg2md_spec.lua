local mock = require('luassert.mock')
local stub = require('luassert.stub')
local providers = require "bible.providers"
local bg2md = require "bible.providers.bg2md"
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
      book = {},
      verses = {},
      footnotes = {},
      crossrefs = {}
    }

    local out = bg2md:lookup_verse("john5:1-5", {}, function(result)

      local loc_name = "verses"
      -- Print(result)
      local regex_patt = {
        query = {
          match = "",
          capture = ""
        },
        chapter = {
          match = "",
          capture = ""
        },
        verses = {
          match = "",
          capture = ""
        },
        footnotes = {
          match = "",
          capture = ""
        },
        crossrefs = {
          match = "",
          capture = ""
        },

      }

      for i, line in ipairs(result.verses) do
        local entry

        -- local hash_count = string.find(line, "# %w")
        local o1, o2, o3 = string.find(line, "[#] (%w)")
        Print(o1)
        Print(o2)
        Print(o3)
        -- if hash_count == 1 then
        --   loc_name = "query"
        --   _, _, capture = string.find(line, "# (%w+)$")
        --   entry = capture
        -- elseif hash_count == 3 then
        --   _, _, capture = string.find(line, "### (%w+)$")
        --   loc_name = capture
        -- elseif hash_count == 2 then
        --   loc_name = "chapter"
        --   _, _, chapter = string.find(line, "## (%w+)$")
        --   entry = chapter
        -- elseif hash_count == 6 then
        --   loc_name = "verses"
        --   _, _, num, text = string.find(line, "###### (%d+) (.*)$")
        --   entry[num] = text
        -- end

        -- if not util.isempty(line) then
        --   table.insert(final[string.lower(loc_name)], entry)
        -- end

      end

      Print(final)

      eq(2, 2)

    end)
  end)


end)
