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
  local tests_path = Helpers.getFixturePath("bun_tests")
  child.cmd("cd " .. tests_path)
  child.cmd("e tests/describe.test.ts")

  child.lua([[
    require("nio").run(function()
      require("neotest-bun")
      require("neotest").setup({
        adapters = {
          require("neotest-bun")
        }
      })
      require('neotest.logging'):set_level('TRACE')

      local ok, err = pcall(function()
        local client = require("neotest").run.run(vim.fn.expand("%"))

        -- require("neotest").output.open({ last_run = true, enter = true })
        -- local bufnr = vim.api.nvim_get_current_buf()
        -- vim.b.output = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        -- require("neotest").output.close()

        -- require("neotest").output_panel.open()
        -- local bufnr = require("neotest").output_panel.buffer()
        -- -- vim.b.output = require("neotest").run.get_last_run()
        local adapter = require("neotest").state.adapter_ids()[1]
        -- -- -- vim.b.output = require("neotest").state.status_counts(adapter)
        -- vim.b.output = require("neotest").state.positions(adapter)
        -- vim.b.output = require("neotest.client")():get_results()
        vim.b.output = require("neotest").state.status_counts(adapter).running
      end)

      if not ok then
        vim.b.result = err
      end
    end)
  ]])

  -- vim.uv.sleep(1000)

  Helpers.waitFor(function()
    child.lua([[
      local ok, err = pcall(function()
        local adapter = require("neotest").state.adapter_ids()[1]
        vim.b.status_counts = require("neotest").state.status_counts(adapter)
      end)

      if not ok then
        vim.b.status_counts = err
      end
    ]])
    print("running is", vim.inspect(child.b.status_counts), "\n")
    return child.b.status_counts.total > 0
  end, 5000)

  -- vim.uv.sleep(1000)
  print(tostring(ss))

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
  print(vim.inspect(child.b.result))
  print("\n\n\n")

  local screenshot = child.get_screenshot()
  MiniTest.expect.reference_screenshot(screenshot)
  -- MiniTest.expect.equality(child.b.output, {})
end

return T
