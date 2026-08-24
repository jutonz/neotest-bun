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
T["bun.escapeTestPattern()"] = MiniTest.new_set()
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

-- bun treats --test-name-pattern as a regex, so a name containing a
-- metacharacter must be escaped or it selects the wrong tests -- or none.
T["bun.escapeTestPattern()"]["escapes regex metacharacters"] = function()
  local cases = {
    { "handles (parens)", "handles \\(parens\\)" },
    { "a|b", "a\\|b" },
    { "returns 1.5", "returns 1\\.5" },
    { "repeat x{2}", "repeat x\\{2\\}" },
    { "maybe?", "maybe\\?" },
    { "star*", "star\\*" },
    { "plus+", "plus\\+" },
    { "[bracket]", "\\[bracket\\]" },
    { "caret^inside", "caret\\^inside" },
    { "dollar$sign", "dollar\\$sign" },
    { "back\\slash", "back\\\\slash" },
  }

  for _, case in ipairs(cases) do
    local name, expected = case[1], case[2]
    MiniTest.expect.equality(bun.escapeTestPattern(name), expected)
  end
end

-- Escaping these relies on identity escapes that stricter regex engines reject,
-- and none of them are metacharacters.
T["bun.escapeTestPattern()"]["leaves non-metacharacters alone"] = function()
  local cases = { "it doesn't work", "path/to/thing", "dash-case", "plain name" }

  for _, name in ipairs(cases) do
    MiniTest.expect.equality(bun.escapeTestPattern(name), name)
  end
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
  local xml = Helpers.readFixtureFile("junit/single-failure.test.ts.xml")
  local root = "/root/path"

  local results = bun.xmlToResults(root, xml)

  local expected = {
    [root .. "/tests/single-failure.test.ts::it doesn't work"] = {
      status = "failed",
    },
  }
  MiniTest.expect.equality(expected, results)
end

T["bun.xmlToResults()"]["parses junit with a multiple skipped tests"] = function()
  local xml = Helpers.readFixtureFile("junit/two-skipped.test.ts.xml")
  local root = "/root/path"

  local results = bun.xmlToResults(root, xml)

  local expected = {
    [root .. "/tests/two-skipped.test.ts::first"] = {
      status = "skipped",
    },
    [root .. "/tests/two-skipped.test.ts::second"] = {
      status = "skipped",
    },
  }
  MiniTest.expect.equality(expected, results)
end

T["bun.xmlToResults()"]["considers a test to pass if it's not skipped or failed"] = function()
  local xml = Helpers.readFixtureFile("junit/one-passed.test.ts.xml")
  local root = "/root/path"

  local results = bun.xmlToResults(root, xml)

  local expected = {
    [root .. "/tests/one-passed.test.ts::it works"] = {
      status = "passed",
    },
  }
  MiniTest.expect.equality(expected, results)
end

T["bun.xmlToResults()"]["handles output with two testsuites"] = function()
  local xml = Helpers.readFixtureFile("junit/two-testsuites.test.ts.xml")
  local root = "/root/path"

  local results = bun.xmlToResults(root, xml)

  local expected = {
    [root .. "/tests/two-testsuites.test.ts::first suite::first test"] = {
      status = "skipped",
    },
    [root .. "/tests/two-testsuites.test.ts::second suite::second test"] = {
      status = "skipped",
    },
  }
  MiniTest.expect.equality(expected, results)
end

T["bun.xmlToResults()"]["reports every status in a single testsuite"] = function()
  local xml = Helpers.readFixtureFile("junit/all-statuses.test.js.xml")
  local root = "/root/path"

  local results = bun.xmlToResults(root, xml)

  local expected = {
    [root .. "/tests/all-statuses.test.js::pass"] = { status = "passed" },
    [root .. "/tests/all-statuses.test.js::skip"] = { status = "skipped" },
    [root .. "/tests/all-statuses.test.js::fail"] = { status = "failed" },
  }
  MiniTest.expect.equality(expected, results)
end

T["bun.xmlToResults()"]["handles the empty failure element older bun emits"] = function()
  local xml = Helpers.readFixtureFile("junit/legacy-empty-failure.xml")
  local root = "/root/path"

  local results = bun.xmlToResults(root, xml)

  local expected = {
    [root .. "/tests/single-failure.test.ts::it doesn't work"] = { status = "failed" },
  }
  MiniTest.expect.equality(expected, results)
end

T["bun.xmlToResults()"]["handles output with nested describe blocks"] = function()
  local xml = Helpers.readFixtureFile("junit/describe.test.ts.xml")
  local root = "/root/path"

  local results = bun.xmlToResults(root, xml)

  local expected = {
    [root .. "/tests/describe.test.ts::the describe block::the test"] = {
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
