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
T["bun.ensureIsSequence()"] = MiniTest.new_set()
T["bun.parseClassname()"] = MiniTest.new_set()
T["bun.xmlToResults()"] = MiniTest.new_set()

T["bun.fileExists()"]["is true if the file exists"] = function()
  local path = Helpers.getCurrentPath()
  MiniTest.expect.equality(bun.fileExists(path), true)
end

T["bun.fileExists()"]["is false if the file doesn't exist"] = function()
  local path = Helpers.getCurrentPath()
  path = string.gsub(path, ".lua", ".luaf")
  MiniTest.expect.equality(bun.fileExists(path), false)
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

T["bun.ensureIsSequence()"]["converts a single table into a sequence of tables"] = function()
  local table = { status = "passed" }
  MiniTest.expect.equality({ table }, bun.ensureIsSequence(table))
end

T["bun.ensureIsSequence()"]["if the argument is already a sequence of tables, does nothing"] = function()
  local sequenceOfTables = { { status = "passed" }, { status = "failed" } }
  MiniTest.expect.equality(sequenceOfTables, bun.ensureIsSequence(sequenceOfTables))
end

T["bun.parseClassname()"]["handles nested describe blocks"] = function()
  local classname = "when the component is rendered &gt; AppRoot"
  local actual = bun.parseClassname(classname)
  MiniTest.expect.equality("AppRoot::when the component is rendered", actual)
end

T["bun.parseClassname()"]["doesn't modify classnames which aren't nested"] = function()
  local classname = "AppRoot"
  local actual = bun.parseClassname(classname)
  MiniTest.expect.equality("AppRoot", actual)
end

T["bun.xmlToResults()"]["parses junit with a single failure"] = function()
  local xml = Helpers.readFixtureFile("junit/single-failure.xml")
  local root = "/root/path"

  local results = bun.xmlToResults(root, xml)

  local expected = {
    [root .. "/test/frontend/pages/Providers/Index.test.tsx::Index::marks all providers as Active"] = {
      status = "failed",
    },
  }
  MiniTest.expect.equality(expected, results)
end

T["bun.xmlToResults()"]["parses junit with a multiple skipped tests"] = function()
  local xml = Helpers.readFixtureFile("junit/two-skipped.xml")
  local root = "/root/path"

  local results = bun.xmlToResults(root, xml)

  local expected = {
    [root .. "/test/frontend/pages/Providers/Index.test.tsx::Index::has an empty state if there are no providers"] = {
      status = "skipped",
    },
    [root .. "/test/frontend/pages/Providers/Index.test.tsx::Index::marks all providers as Active"] = {
      status = "skipped",
    },
  }
  MiniTest.expect.equality(expected, results)
end

T["bun.xmlToResults()"]["considers a test to pass if it's not skipped or failed"] = function()
  local xml = Helpers.readFixtureFile("junit/one-passed.xml")
  local root = "/root/path"

  local results = bun.xmlToResults(root, xml)

  local expected = {
    [root .. "/test/frontend/pages/Providers/Index.test.tsx::Index::renders a list of Providers"] = {
      status = "passed",
    },
  }
  MiniTest.expect.equality(expected, results)
end

T["bun.xmlToResults()"]["handles output with two testsuites"] = function()
  local xml = Helpers.readFixtureFile("junit/two-testsuites.xml")
  local root = "/root/path"

  local results = bun.xmlToResults(root, xml)

  local expected = {
    [root .. "/test/frontend/pages/MarketplaceModels/DetailsDrawer.test.tsx::DetailsDrawer::renders attributes from a minimally filled ModelDetail"] = {
      status = "passed",
    },
    [root .. "/test/frontend/pages/MarketplaceModels/DetailsDrawer.test.tsx::DetailsDrawer::renders attributes from the ModelDetail"] = {
      status = "passed",
    },
    [root .. "/test/frontend/pages/MarketplaceModels/SubscriptionDrawer.test.tsx::SubscriptionDrawer::renders attributes from a Legacy System Subscription"] = {
      status = "passed",
    },
    [root .. "/test/frontend/pages/MarketplaceModels/SubscriptionDrawer.test.tsx::SubscriptionDrawer::renders attributes from the Subscription"] = {
      status = "passed",
    },
  }
  MiniTest.expect.equality(expected, results)
end

T["bun.xmlToResults()"]["handles output with nested describe blocks"] = function()
  local xml = Helpers.readFixtureFile("junit/nested-describe.xml")
  local root = "/root/path"

  local results = bun.xmlToResults(root, xml)

  local expected = {
    [root .. "/test/frontend/components/Layout/AppRoot.test.tsx::AppRoot::when the component is rendered::renders the marketplace navigation for marketplace users"] = {
      status = "passed",
    },
    [root .. "/test/frontend/components/Layout/AppRoot.test.tsx::AppRoot::when the component is rendered::renders the service portal navigation for marketplace  and service portal users"] = {
      status = "passed",
    },
  }
  MiniTest.expect.equality(expected, results)
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
