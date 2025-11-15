local Helpers = dofile("tests/helpers.lua")
local adapter = require("neotest-bun")
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

T["adapter.is_test_file"] = MiniTest.new_set()
T["adapter.discover_positions"] = MiniTest.new_set()

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

T["adapter.discover_positions"]["builds simple positions"] = function()
  local tests_path = Helpers.getFixturePath("bun_tests/tests")
  child.cmd("cd " .. tests_path)
  child.lua([[
    require("nio").run(function()
      local adapter = require("neotest-bun")
      local test = "simple.test.ts"
      local ok, err = pcall(function()
        vim.b.result = adapter.discover_positions(test):to_list()
      end)
      if not ok then
        vim.b.result = err
      end
    end)
  ]])

  Helpers.waitFor(function()
    return child.b.result ~= vim.NIL
  end, 1000)

  MiniTest.expect.equality(child.b.result, {
    {
      id = "simple.test.ts",
      name = "simple.test.ts",
      path = "simple.test.ts",
      range = { 0, 0, 7, 0 },
      type = "file",
    },
    {
      {
        id = "simple.test.ts::something",
        is_parameterized = false,
        name = "something",
        path = "simple.test.ts",
        range = { 2, 0, 6, 2 },
        type = "namespace",
      },
      {
        {
          id = "simple.test.ts::something::2 + 2",
          is_parameterized = false,
          name = "2 + 2",
          path = "simple.test.ts",
          range = { 3, 2, 5, 4 },
          type = "test",
        },
      },
    },
  })
end

return T
