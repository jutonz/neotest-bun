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

T["integration"]["tests/describe.test.ts"] = function()
  child.cmd("cd " .. Helpers.getFixturePath("bun_tests"))
  child.cmd("e tests/describe.test.ts")

  Helpers.runCurrentTestFile(child)

  local screenshot = child.get_screenshot()
  print(tostring(screenshot))
  -- MiniTest.expect.reference_screenshot(screenshot)

  -- vim.loop.sleep(1000)
  child.b.output = false
  child.lua([[
    require("nio").run(function()
      require("neotest").output.open({ last_run = true, enter = true })
      local bufnr = require("neotest").output_panel.buffer()
      -- vim.uv.sleep(1000)
      -- local bufnr = vim.api.nvim_get_current_buf()
      vim.b.output = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    end)
  ]])

  Helpers.waitFor(function()
    return child.b.output ~= false
  end, 5000)

  print("\n\n\n")
  print("Test output follows:\n")
  print("----------------------------------\n")
  print(table.concat(child.b.output, "\n"))
  print("\n----------------------------------\n")
  print("\n")
end

return T
