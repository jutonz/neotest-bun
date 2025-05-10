local Helpers = dofile("tests/helpers.lua")
local bun = require("neotest-bun/util/bun")

-- See https://github.com/echasnovski/mini.nvim/blob/main/lua/mini/test.lua for more documentation

local child = Helpers.new_child_neovim()

local T = MiniTest.new_set({
  hooks = {
    -- This will be executed before every (even nested) case
    pre_case = function()
      -- Restart child process with custom 'init.lua' script
      child.restart({ "-u", "scripts/minimal_init.lua" })
    end,
    -- This will be executed one after all tests from this set are finished
    post_once = child.stop,
  },
})

T["bun.fileExists()"] = MiniTest.new_set()
T["bun.isBunProject()"] = MiniTest.new_set()
T["bun.xmlToResults()"] = MiniTest.new_set()

T["bun.fileExists()"]["is true if the file exists"] = function()
  local path = Helpers.getCurrentPath()
  MiniTest.expect.equality(
    bun.fileExists(path),
    true
  )
end

T["bun.fileExists()"]["is false if the file doesn't exist"] = function()
  local path = Helpers.getCurrentPath()
  path = string.gsub(path, ".lua", ".luaf")
  MiniTest.expect.equality(
    bun.fileExists(path),
    false
  )
end

T["bun.isBunProject()"]["is true if bun.lock exists at the root of the working directory"] = function()
  local path = Helpers.getFixturePath("dir-with-bun-lock/")
  child.cmd("cd " .. path)

  local isBunProject = child.lua_get([[ require("neotest-bun/util/bun").isBunProject() ]])

  MiniTest.expect.equality(isBunProject, true)
end

T["bun.isBunProject()"]["is false if no bun.lock exists at the root of the working directory"] = function()
  local path = Helpers.getFixturePath()
  child.cmd("cd " .. path)

  local isBunProject = child.lua_get([[ require("neotest-bun/util/bun").isBunProject() ]])

  MiniTest.expect.equality(isBunProject, false)
end

T["bun.xmlToResults()"]["parses junit with a failure"] = function()
  -- local xml = Helpers.readFixtureFile("junit/with-failure.xml")
  --
  -- local results = bun.xmlToResults(xml)
  --
  -- vim.print(results)
  -- child.cmd("cd " .. path)
  --
  -- local isBunProject = child.lua_get([[ require("neotest-bun/util/bun").isBunProject() ]])

  -- MiniTest.expect.equality(isBunProject, false)
end

-- T["setup()"]["overrides default values"] = function()
--   child.lua([[require('neotest-bun').setup({
--         -- write all the options with a value different than the default ones
--         debug = true,
--     })]])
--
--   -- assert the value, and the type
--   Helpers.expect.config(child, "debug", true)
--   Helpers.expect.config_type(child, "debug", "boolean")
-- end

return T
