local Helpers = dofile("tests/helpers.lua")
local adapter = require("neotest-bun")
local child = Helpers.new_child_neovim()

local T = MiniTest.new_set({
  hooks = {
    -- This will be executed before every (even nested) case
    pre_case = function()
      -- Restart child process with custom 'adapter.lua' script
      child.restart({ "-u", "scripts/minimal_adapter.lua" })
    end,
    -- This will be executed one after all tests from this set are finished
    post_once = child.stop,
  },
})

T["adapter.is_test_file"] = MiniTest.new_set()

T["adapter.is_test_file"]["is false if the file doesn't exist"] = function()
  MiniTest.expect.equality(adapter.is_test_file(nil), false)
end

T["adapter.is_test_file"]["is true if the file ends in .test.tsx"] = function()
  local path = Helpers.getFixturePath("bun_tests/tests/simple.test.tsx")
  MiniTest.expect.equality(adapter.is_test_file(path), true)
end

T["adapter.is_test_file"]["is true if the file ends in .test.ts"] = function()
  local path = Helpers.getFixturePath("bun_tests/tests/simple.test.ts")
  MiniTest.expect.equality(adapter.is_test_file(path), true)
end

T["adapter.is_test_file"]["is false if the file ends with something else"] = function()
  local path = Helpers.getCurrentPath()
  MiniTest.expect.equality(adapter.is_test_file(path), false)
end

return T
