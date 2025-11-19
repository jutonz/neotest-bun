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

local includes_pattern = function(list, pattern)
  return vim.iter(list):any(function(v)
    return v:match(pattern)
  end)
end

T["adapter.is_test_file"] = MiniTest.new_set()
T["adapter.discover_positions"] = MiniTest.new_set()
T["adapter.build_spec"] = MiniTest.new_set()

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
      local test = "one-passed.test.ts"
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
      id = "one-passed.test.ts",
      name = "one-passed.test.ts",
      path = "one-passed.test.ts",
      range = { 0, 0, 5, 0 },
      type = "file",
    },
    {
      {
        id = "one-passed.test.ts::it works",
        is_parameterized = false,
        name = "it works",
        path = "one-passed.test.ts",
        range = { 2, 0, 4, 2 },
        type = "test",
      },
    },
  })
end

T["adapter.build_spec"]["is nil if the tree is nil"] = function()
  local tree = nil
  local strategy = "something"
  local args = { tree, strategy }

  local spec = adapter.build_spec(args)

  MiniTest.expect.equality(spec, nil)
end

T["adapter.build_spec"]["includes the correct reporter flags"] = function()
  child.b.path = Helpers.getFixturePath("bun_tests/tests/one-passed.test.ts")

  child.lua([[
    local ok, err = pcall(function()
      require("nio").run(function()
        local adapter = require("neotest-bun")
        local positions = adapter.discover_positions(vim.b.path):to_list()
        local Tree = require("neotest.types").Tree
        local tree = Tree.from_list(positions, function(pos)
          return pos.id
        end)
        local spec = adapter.build_spec({ tree = tree })
        vim.b.command = spec.command
      end)
    end)

    if not ok then
      vim.b.err = err
    end
  ]])

  Helpers.waitFor(function()
    return child.b.command ~= vim.NIL or child.b.err ~= vim.NIL
  end, 2000)

  MiniTest.expect.equality(child.b.err, vim.NIL)
  local command = child.b.command
  MiniTest.expect.equality(vim.tbl_contains(command, "--reporter=junit"), true)
  MiniTest.expect.equality(includes_pattern(command, "^%-%-reporter%-outfile="), true)
end

T["adapter.build_spec"]["includes additional_args from config"] = function()
  child.b.path = Helpers.getFixturePath("bun_tests/tests/one-passed.test.ts")

  child.lua([[
    local ok, err = pcall(function()
      require("nio").run(function()
        local adapter = require("neotest-bun")({
          additional_args = { "--some-arg" },
        })
        local positions = adapter.discover_positions(vim.b.path):to_list()
        local Tree = require("neotest.types").Tree
        local tree = Tree.from_list(positions, function(pos)
          return pos.id
        end)
        local spec = adapter.build_spec({ tree = tree })
        vim.b.command = spec.command
      end)
    end)

    if not ok then
      vim.b.err = err
    end
  ]])

  Helpers.waitFor(function()
    return child.b.command ~= vim.NIL or child.b.err ~= vim.NIL
  end, 2000)

  MiniTest.expect.equality(child.b.err, vim.NIL)
  local command = child.b.command
  MiniTest.expect.equality(vim.tbl_contains(command, "--some-arg"), true)
end

return T
