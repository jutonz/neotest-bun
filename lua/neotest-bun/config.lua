local log = require("neotest-bun.util.log")

local NeotestBun = {}

--- NeotestBun configuration with its default values.
---
---@type table
--- Default values:
---@eval return MiniDoc.afterlines_to_code(MiniDoc.current.eval_section)
NeotestBun.options = {
  -- Prints useful logs about what event are triggered, and reasons actions are executed.
  debug = false,
}

---@private
local defaults = vim.deepcopy(NeotestBun.options)

--- Defaults NeotestBun options by merging user provided options with the default plugin values.
---
---@param options table Module config table. See |NeotestBun.options|.
---
---@private
function NeotestBun.defaults(options)
  NeotestBun.options = vim.deepcopy(vim.tbl_deep_extend("keep", options or {}, defaults or {}))

  -- let your user know that they provided a wrong value, this is reported when your plugin is executed.
  assert(
    type(NeotestBun.options.debug) == "boolean",
    "`debug` must be a boolean (`true` or `false`)."
  )

  return NeotestBun.options
end

--- Define your neotest-bun setup.
---
---@param options table|nil Module config table. See |NeotestBun.options|.
---
---@usage `require("neotest-bun").setup()` (add `{}` with your |NeotestBun.options| table)
function NeotestBun.setup(options)
  NeotestBun.options = NeotestBun.defaults(options or {})

  log.warn_deprecation(NeotestBun.options)

  return NeotestBun.options
end

return NeotestBun
