local log = require("neotest-bun.util.log")
local state = require("neotest-bun.state")

-- internal methods
local main = {}

-- Toggle the plugin by calling the `enable`/`disable` methods respectively.
--
---@param scope string: internal identifier for logging purposes.
---@private
function main.toggle(scope)
  if state.get_enabled(state) then
    log.debug(scope, "neotest-bun is now disabled!")

    return main.disable(scope)
  end

  log.debug(scope, "neotest-bun is now enabled!")

  main.enable(scope)
end

--- Initializes the plugin, sets event listeners and internal state.
---
--- @param scope string: internal identifier for logging purposes.
---@private
function main.enable(scope)
  if state.get_enabled(state) then
    log.debug(scope, "neotest-bun is already enabled")

    return
  end

  state.set_enabled(state)

  -- saves the state globally to `_G.NeotestBun.state`
  state.save(state)
end

--- Disables the plugin for the given tab, clear highlight groups and autocmds, closes side buffers and resets the internal state.
---
--- @param scope string: internal identifier for logging purposes.
---@private
function main.disable(scope)
  if not state.get_enabled(state) then
    log.debug(scope, "neotest-bun is already disabled")

    return
  end

  state.set_disabled(state)

  -- saves the state globally to `_G.NeotestBun.state`
  state.save(state)
end

return main
