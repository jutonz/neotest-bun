local main = require("neotest-bun/main")
local async = require("neotest/async")
local config = require("neotest-bun/config")
local bun = require("neotest-bun/util/bun")
local lib = require("neotest/lib")
local neotestFileUtil = require("neotest/lib/file")
local logger = require("neotest.logging")

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

NeotestBun.filter_dir = function(name)
  return name ~= "node_modules"
end

NeotestBun.is_test_file = function(file_path)
  if file_path == nil then
    return false
  end

  if string.find(file_path, ".test.tsx") then
    return true
  else
    return false
  end
end

NeotestBun.discover_positions = function(path)
  local query = [[
    ; -- Namespaces --
    ; Matches: `describe('context', () => {})`
    ((call_expression
      function: (identifier) @func_name (#eq? @func_name "describe")
      arguments: (arguments (string (string_fragment) @namespace.name) (arrow_function))
    )) @namespace.definition
    ; Matches: `describe('context', function() {})`
    ((call_expression
      function: (identifier) @func_name (#eq? @func_name "describe")
      arguments: (arguments (string (string_fragment) @namespace.name) (function_expression))
    )) @namespace.definition
    ; Matches: `describe.only('context', () => {})`
    ((call_expression
      function: (member_expression
        object: (identifier) @func_name (#any-of? @func_name "describe")
      )
      arguments: (arguments (string (string_fragment) @namespace.name) (arrow_function))
    )) @namespace.definition
    ; Matches: `describe.only('context', function() {})`
    ((call_expression
      function: (member_expression
        object: (identifier) @func_name (#any-of? @func_name "describe")
      )
      arguments: (arguments (string (string_fragment) @namespace.name) (function_expression))
    )) @namespace.definition
    ; Matches: `describe.each(['data'])('context', () => {})`
    ((call_expression
      function: (call_expression
        function: (member_expression
          object: (identifier) @func_name (#any-of? @func_name "describe")
        )
      )
      arguments: (arguments (string (string_fragment) @namespace.name) (arrow_function))
    )) @namespace.definition
    ; Matches: `describe.each(['data'])('context', function() {})`
    ((call_expression
      function: (call_expression
        function: (member_expression
          object: (identifier) @func_name (#any-of? @func_name "describe")
        )
      )
      arguments: (arguments (string (string_fragment) @namespace.name) (function_expression))
    )) @namespace.definition

    ; -- Tests --
    ; Matches: `test('test') / it('test')`
    ((call_expression
      function: (identifier) @func_name (#any-of? @func_name "it" "test")
      arguments: (arguments (string (string_fragment) @test.name) [(arrow_function) (function_expression)])
    )) @test.definition
    ; Matches: `test.only('test') / it.only('test')`
    ((call_expression
      function: (member_expression
        object: (identifier) @func_name (#any-of? @func_name "test" "it")
      )
      arguments: (arguments (string (string_fragment) @test.name) [(arrow_function) (function_expression)])
    )) @test.definition
    ; Matches: `test.each(['data'])('test') / it.each(['data'])('test')`
    ((call_expression
      function: (call_expression
        function: (member_expression
          object: (identifier) @func_name (#any-of? @func_name "it" "test")
          property: (property_identifier) @each_property (#eq? @each_property "each")
        )
      )
      arguments: (arguments (string (string_fragment) @test.name) [(arrow_function) (function_expression)])
    )) @test.definition
  ]]

  local positions = lib.treesitter.parse_positions(path, query, {
    nested_tests = false,
    build_position = 'require("neotest-bun").build_position',
  })

  return positions
end

local function get_match_type(captured_nodes)
  if captured_nodes["test.name"] then
    return "test"
  end
  if captured_nodes["namespace.name"] then
    return "namespace"
  end
end

function NeotestBun.build_position(file_path, source, captured_nodes)
  local match_type = get_match_type(captured_nodes)
  if not match_type then
    return
  end

  ---@type string
  local name = vim.treesitter.get_node_text(captured_nodes[match_type .. ".name"], source)
  local definition = captured_nodes[match_type .. ".definition"]

  return {
    type = match_type,
    path = file_path,
    name = name,
    range = { definition:range() },
    is_parameterized = captured_nodes["each_property"] and true or false,
  }
end

NeotestBun.build_spec = function(args)
  local results_path = async.fn.tempname() .. ".xml"
  local tree = args.tree

  if not tree then
    return
  end

  local pos = args.tree:data()
  local testNamePattern = "'.*'"

  if pos.type == "test" or pos.type == "namespace" then
    -- pos.id in form "path/to/file::Describe text::test text"
    local testName = string.sub(pos.id, string.find(pos.id, "::") + 2)
    testName, _ = string.gsub(testName, "::", " ")
    testNamePattern = bun.escapeTestPattern(testName)
    testNamePattern = "'^" .. testNamePattern
    if pos.type == "test" then
      testNamePattern = testNamePattern .. "$'"
    else
      testNamePattern = testNamePattern .. "'"
    end
  end

  local binary = "bun test"
  local command = vim.split(binary, "%s+")

  vim.list_extend(command, {
    "--reporter=junit",
    "--reporter-outfile=" .. results_path,
    bun.escapeTestPattern(vim.fs.normalize(pos.path)),
  })

  -- creating empty file for streaming results
  lib.files.write(results_path, "")
  local stream_data, stop_stream = neotestFileUtil.stream(results_path)

  return {
    command = command,
    context = {
      results_path = results_path,
      file = pos.path,
      stop_stream = stop_stream,
    },
    stream = function()
      return function()
        local new_results = stream_data()
        local ok, parsed = pcall(vim.json.decode, new_results, { luanil = { object = true } })

        if not ok or not parsed.testResults then
          return {}
        end

        return bun.parsedJsonToResults(parsed, results_path, nil)
      end
    end,
  }
end

function NeotestBun.results(spec, b, tree)
  spec.context.stop_stream()

  local output_file = spec.context.results_path

  local success, data = pcall(lib.files.read, output_file)

  if not success then
    logger.error("No test output file found ", output_file)
    return {}
  end

  local ok, parsed = pcall(vim.xml.decode, data, { luanil = { object = true } })

  if not ok then
    logger.error("Failed to parse test output json ", output_file)
    return {}
  end

  local results = bun.parsedJsonToResults(parsed, output_file, b.output)

  return results
end

_G.NeotestBun = NeotestBun

return _G.NeotestBun
