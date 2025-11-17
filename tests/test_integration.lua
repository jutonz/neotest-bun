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

return T
