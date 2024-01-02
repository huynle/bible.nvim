local mock = require('luassert.mock')
local stub = require('luassert.stub')
local providers = require "bible.providers"
local renderer = require "bible.renderer"
local util = require("bible.util")

local eq = assert.are.same

describe("renderer", function()
  local result1 = {
    name = "john1:1",
    chapter = "",
    verses = {},
    commentary = "",
    value = "some string for john 1:1",
    version = "NABRE",
  }

  local result2 = {
    name = "john2:1",
    chapter = "",
    verses = {},
    commentary = "",
    value = "some string for john 2:1",
    version = "NABRE",
  }

  local result3 = {
    name = "john3:1",
    chapter = "",
    verses = {},
    commentary = "",
    value = "some string for john 3:1",
    version = "VET",
  }

  local result4 = {
    name = "john3:1",
    chapter = "",
    verses = {},
    commentary = "",
    value = "some string for john 4:1",
    version = "NABRE",
  }

  -- it("simple render", function()
  --   local results = {}
  --   table.insert(results, result1)
  --   table.insert(results, result2)
  --   table.insert(results, result3)
  --   local grouped = renderer.render_group({}, results, {})
  --   -- Print(grouped)
  --   eq(util.count(grouped), 2)
  -- end)



end)
