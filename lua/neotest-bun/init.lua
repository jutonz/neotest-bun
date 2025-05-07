local main = require("neotest-bun.main")
local config = require("neotest-bun.config")
local lib = require("neotest/lib")

local NeotestBun = {
  name = "neotest-bun",
}

--- Toggle the plugin by calling the `enable`/`disable` methods respectively.
function NeotestBun.toggle()
  if _G.NeotestBun.config == nil then
    _G.NeotestBun.config = config.options
  end

  main.toggle("public_api_toggle")
end

--- Initializes the plugin, sets event listeners and internal state.
function NeotestBun.enable(scope)
  if _G.NeotestBun.config == nil then
    _G.NeotestBun.config = config.options
  end

  main.toggle(scope or "public_api_enable")
end

--- Disables the plugin, clear highlight groups and autocmds, closes side buffers and resets the internal state.
function NeotestBun.disable()
  main.toggle("public_api_disable")
end

-- setup NeotestBun options and merge them with user provided ones.
function NeotestBun.setup(opts)
  _G.NeotestBun.config = config.setup(opts)
end

NeotestBun.root = function(path)
  return lib.files.match_root_pattern("bun.lock")(path)
end

_G.NeotestBun = NeotestBun

return _G.NeotestBun
