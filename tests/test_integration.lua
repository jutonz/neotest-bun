local Helpers = dofile("tests/helpers.lua")
local child = Helpers.new_child_neovim()

local T = MiniTest.new_set({
  hooks = {
    -- This will be executed before every (even nested) case
    pre_case = function()
      -- Restart child process with custom 'adapter.lua' script
      child.restart({ "-u", "scripts/minimal_init.lua" })
    end,
    -- This will be executed one after all tests from this set are finished
    post_once = child.stop,
  },
})

T["integration"] = MiniTest.new_set()

T["integration"]["tests/describe.test.ts"] = function()
  child.cmd("cd " .. Helpers.getFixturePath("bun_tests"))
  child.cmd("e tests/describe.test.ts")

  Helpers.runCurrentTestFile(child)

  local screenshot = child.get_screenshot()
  MiniTest.expect.reference_screenshot(screenshot, nil, { ignore_attr = true })
end

T["integration"]["tests/all-statuses.test.js"] = function()
  child.cmd("cd " .. Helpers.getFixturePath("bun_tests"))
  child.cmd("e tests/all-statuses.test.js")

  Helpers.runCurrentTestFile(child)

  local screenshot = child.get_screenshot()
  MiniTest.expect.reference_screenshot(screenshot, nil, { ignore_attr = true })
end

-- Guards against the `--test-name-pattern` bun builds for a single test not
-- matching anything, which silently runs zero tests instead of failing loudly.
T["integration"]["runs a single test inside a describe block"] = function()
  child.cmd("cd " .. Helpers.getFixturePath("bun_tests"))
  child.cmd("e tests/describe.test.ts")
  -- `test("the test", ...)` lives on line 4.
  child.api.nvim_win_set_cursor(0, { 4, 0 })

  Helpers.runNearestTest(child)

  local counts = Helpers.getStatusCounts(child)
  MiniTest.expect.equality(counts.passed, 1)
  MiniTest.expect.equality(counts.failed, 0)
end

return T
