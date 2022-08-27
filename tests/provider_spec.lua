local mock = require('luassert.mock')
local stub = require('luassert.stub')
local providers = require "bible.providers"
local util = require("bible.util")

local eq = assert.are.same

describe("providers", function()
  -- it("*can be required*", function()
  --   require("bible")
  -- end)

  -- it("Get default provider to get verse", function()
  --   local provider_options = {}
  --   require("bible.providers").get("john1:1", provider_options, function(results)
  --     -- Print(results)
  --     assert(results)
  --     -- assert.has_property("value", results)
  --     -- assert.array(results).has.no.holes()
  --   end)
  -- end)

  -- it("multiple verses", function()
  --   local provider_options = {}
  --   providers.get("john1:1;acts1:1", provider_options, function(results)
  --     Print(results)
  --     local grouped = providers:group_by(results, {
  --       enabled = true,
  --       group_by = { "version" }
  --     })
  --     assert(grouped)
  --     -- assert.has_property("value", results)
  --     -- assert.array(results).has.no.holes()
  --   end)
  -- end)

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

  it("single grouping", function()
    local results = {}
    table.insert(results, result1)
    table.insert(results, result2)
    table.insert(results, result3)
    local grouped = providers:group(results, "version")
    Print(grouped)
    eq(util.count(grouped), 2)
  end)

  -- it("multiple grouping", function()
  --   local results = {}
  --   table.insert(results, result1)
  --   table.insert(results, result2)
  --   table.insert(results, result3)
  --   table.insert(results, result4)

  --   local group_opts = {
  --     enabled = true,
  --     group_by = {
  --       [1] = "version",
  --       [2] = "name"
  --     }
  --   }
  --   local grouped = providers:group_by(results, group_opts)
  --   Print(grouped)
  --   eq(util.count(grouped), 2)
  -- end)



end)


-- -- MOCKING
-- describe("example", function()
--   -- instance of module to be tested
--   local testModule = require('bible')
--   -- mocked instance of api to interact with

--   describe("realistic_func", function()
--     it("Should make expected calls to api, fully mocked", function()
--       -- mock the vim.api
--       local api = mock(vim.api, true)

--       -- set expectation when mocked api call made
--       api.nvim_create_buf.returns(5)

--       testModule.realistic_func()

--       -- assert api was called with expcted values
--       assert.stub(api.nvim_create_buf).was_called_with(false, true)
--       -- assert api was called with set expectation
--       assert.stub(api.nvim_command).was_called_with("sbuffer 5")

--       -- revert api back to it's former glory
--       mock.revert(api)
--     end)

--     it("Should mock single api call", function()
--       -- capture some number of windows and buffers before
--       -- running our function
--       local buf_count = #vim.api.nvim_list_bufs()
--       local win_count = #vim.api.nvim_list_wins()
--       -- stub a single function in the api
--       stub(vim.api, "nvim_command")

--       testModule.realistic_func()

--       -- capture some details after running out function
--       local after_buf_count = #vim.api.nvim_list_bufs()
--       local after_win_count = #vim.api.nvim_list_wins()

--       -- why 3 not two? NO IDEA! The point is we mocked
--       -- nvim_command and there is only a single window
--       assert.equals(3, buf_count)
--       assert.equals(4, after_buf_count)

--       -- WOOPIE!
--       assert.equals(1, win_count)
--       assert.equals(1, after_win_count)
--     end)
--   end)
-- end)
