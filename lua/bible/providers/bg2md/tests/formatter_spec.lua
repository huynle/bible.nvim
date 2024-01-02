local mock = require('luassert.mock')
local stub = require('luassert.stub')
local bg2md = require "bible.providers.bg2md"
local formatter = require "bible.providers.bg2md.formatter"
local util = require("bible.util")

local eq = assert.are.same
local dir = vim.fn.expand("%:p:h")
local test_file = vim.fn.readfile(dir .. "/lua/bible/providers/bg2md/tests/fixtures/john515.md")

describe("formatter", function()

  it("fommat for nvim", function()
    local out = formatter.collect(test_file)
    local reorg = formatter.reorg(out)
    Print(out)
    -- assert(out)
  end)

  it("parsing crossrefs", function()
    local out = formatter.crossrefs_verses("[^B]: Neh 3:1, 32; 12:39.")
    eq(out,
      { {
        book_name = "Neh",
        verses = { "3:1", "32" }
      }, {
        verses = { "12:39" }
      } })
  end)

  it("check if table is empty", function()
    eq(true, util.istableempty({}))
    eq(true, util.istableempty({
      value = {}
    }))
    eq(true, util.istableempty({
      value = {
        value = nil
      }
    }))
    eq(false, util.istableempty({
      value = {
        value = "asdf"
      }
    }))
  end)
end)
