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

T["integration"] = MiniTest.new_set()

T["integration"]["run simple test"] = function()
  local tests_path = Helpers.getFixturePath("bun_tests/tests")
  child.cmd("cd " .. tests_path)
  child.cmd("e one-passed.test.ts")

  child.lua([[
    require("neotest-bun")
    require("neotest").setup({
      adapters = {
        require("neotest-bun")
      }
    })

    local ok, err = pcall(function()
      require("nio").run(function()
        vim.b.result = require("neotest").run.run(vim.fn.expand("%"))

        require("neotest").output_panel.open()
        local outputBufnr = require("neotest").output_panel.buffer()
        vim.b.output = require("neotest.client")
      end)
    end)

    if not ok then
      vim.b.result = err
    end
  ]])

  vim.uv.sleep(1000)
  local ss = child.get_screenshot()
  print(tostring(ss))

  print("\n\n\n")
  print(vim.inspect(child.b.output))
  print("\n")
  print(vim.inspect(child.b.result))
  print("\n\n\n")

  -- MiniTest.expect.equality(adapter.is_test_file(nil), false)
end

return T
