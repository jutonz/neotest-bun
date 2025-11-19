local config = require("neotest-bun.config")
local defaults = vim.deepcopy(config.options)

local T = MiniTest.new_set()

T["config.setup"] = MiniTest.new_set()

T["config.setup"]["no args uses defaults"] = function()
  config.setup()

  MiniTest.expect.equality(config.options, defaults)
end

T["config.setup"]["allows overwriting defaults"] = function()
  config.setup({ debug = true })

  local expected = vim.tbl_deep_extend("keep", { debug = true }, defaults)
  MiniTest.expect.equality(config.options, expected)
end

T["config.setup"]["validates type of `debug`"] = function()
  local message = "`debug` must be a boolean %(`true` or `false`%)"
  MiniTest.expect.error(function()
    config.setup({ debug = "woah" })
  end, message)
end

return T
