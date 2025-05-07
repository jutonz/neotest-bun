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

-- Tests related to the `setup` method.
T["bun.fileExists()"] = MiniTest.new_set()
T["bun.isBunProject()"] = MiniTest.new_set()

T["bun.fileExists()"]["is true if the file exists"] = function()
  -- child.lua([[require('neotest-bun/util/bun').fileExists('123.txt')]])
  MiniTest.expect.equality(
    bun.fileExists("/Users/jutonz/code/jutonz/test-lua-plugin/neovim-plugin-boilerplate/tests/util/test_bun.lua"),
    true
  )
end

T["bun.fileExists()"]["is false if the file doesn't exist"] = function()
  -- child.lua([[require('neotest-bun/util/bun').fileExists('123.txt')]])
  MiniTest.expect.equality(
    bun.fileExists("/Users/jutonz/code/jutonz/test-lua-plugin/neovim-plugin-boilerplate/tests/util/test_bun.luaf"),
    false
  )
end

T["bun.isBunProject()"]["is true if bun.lock exists at the root of the working directory"] = function()
  child.cmd("cd /Users/jutonz/code/jutonz/test-lua-plugin/neovim-plugin-boilerplate/tests/fixtures/dir-with-bun-lock")
  local isBunProject = child.lua_get([[ require("neotest-bun/util/bun").isBunProject() ]])
  -- child.lua([[ _G.isBunProject = require("neotest-bun/util/bun").isBunProject() ]])
  -- local isBunProject = child.lua_get("_G.isBunProject")
  -- local response = child.cmd_capture("pwd")
  -- local response = child.lua([[
  --   vim.cmd("")
  --   vim.cmd("pwd")
  -- ]])
  --
  MiniTest.expect.equality(isBunProject, true)
end

T["bun.isBunProject()"]["is false if no bun.lock exists at the root of the working directory"] = function()
  child.cmd("cd /Users/jutonz/code/jutonz/test-lua-plugin/neovim-plugin-boilerplate/tests")
  local isBunProject = child.lua_get([[ require("neotest-bun/util/bun").isBunProject() ]])
  MiniTest.expect.equality(isBunProject, false)
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
