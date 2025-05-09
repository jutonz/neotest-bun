local xml2lua = require("xml2lua")
local logger = require("neotest.logging")

local bun = {}

function bun.fileExists(filename)
  local stat = vim.loop.fs_stat(filename)
  if stat and stat.type then
    return true
  else
    return false
  end
end

---@return boolean
function bun.isBunProject()
  local rootBunLock = vim.fn.getcwd() .. "/bun.lock"
  return bun.fileExists(rootBunLock)
end

function bun.escapeTestPattern(s)
  return (
    s:gsub("%(", "%\\(")
    :gsub("%)", "%\\)")
    :gsub("%]", "%\\]")
    :gsub("%[", "%\\[")
    :gsub("%*", "%\\*")
    :gsub("%+", "%\\+")
    :gsub("%-", "%\\-")
    :gsub("%?", "%\\?")
    :gsub("%$", "%\\$")
    :gsub("%^", "%\\^")
    :gsub("%/", "%\\/")
    :gsub("%'", "%\\'")
  )
end

-- {
--   testsuites = {
--     _attr = {
--       assertions = "9",
--       failures = "0",
--       name = "bun test",
--       skipped = "0",
--       tests = "5",
--       time = "0.977182"
--     },
--     testsuite = {
--       _attr = {
--         assertions = "9",
--         failures = "0",
--         hostname = "Justins-MacBook-Pro.local",
--         name = "test/frontend/pages/Providers/Index.test.tsx",
--         skipped = "0",
--         tests = "5",
--         time = "0.396"
--       },
--       testcase = { {
--           _attr = {
--             assertions = "1",
--             classname = "Index",
--             file = "test/frontend/pages/Providers/Index.test.tsx",
--             name = "renders a list of Providers",
--             time = "0.028809"
--           }
--         }, {
--           _attr = {
--             assertions = "5",
--             classname = "Index",
--             file = "test/frontend/pages/Providers/Index.test.tsx",
--             name = "renders attributes of a provider",
--             time = "0.147854"
--           }
--         }, {
--           _attr = {
--             assertions = "1",
--             classname = "Index",
--             file = "test/frontend/pages/Providers/Index.test.tsx",
--             name = "marks all providers as Active",
--             time = "0.067235"
--           }
--         }, {
--           _attr = {
--             assertions = "1",
--             classname = "Index",
--             file = "test/frontend/pages/Providers/Index.test.tsx",
--             name = "has an empty state if there are no providers",
--             time = "0.054429"
--           }
--         }, {
--           _attr = {
--             assertions = "1",
--             classname = "Index",
--             file = "test/frontend/pages/Providers/Index.test.tsx",
--             name = "paginates if there are more than 25 providers",
--             time = "0.100357"
--           }
--         } }
--     }
--   }
-- }
--
function bun.xmlToResults(root, xml, xmlOutputFile, commandOutputFile)
  local tests = {}

  local handler = require("xmlhandler.tree")
  local parser = xml2lua.parser(handler)
  parser:parse(xml)

  -- if commandOutputFile then
  --   local file = io.open(commandOutputFile, "r")
  --   logger.debug(file:read("*all"))
  --   file:close()
  -- end

  -- vim.print(handler.root.testsuites.testsuite.testcase)
  -- logger.debug(xml)
  -- logger.debug(vim.inspect(handler.root))

  -- local file = io.open("/users/jutonz/desktop/hi.xml", "w")
  -- file:write(xml)
  -- file:close()

  for _, testsuite in ipairs(handler.root.testsuites) do
    for _, testcase in ipairs(testsuite.testsuite.testcase) do
      local attrs = testcase._attr
      local status = nil

      if testcase.failure then
        status = "failed"
      elseif testcase.skipped then
        status = "skipped"
      else
        status = "passed"
      end

      local key = root .. "/" .. attrs.file .. "::" .. attrs.classname .. "::" .. attrs.name

      tests[key] = {
        status = status,
      }
    end
  end

  -- for _, testresult in handler.root.testsuites

  -- for _, testResult in pairs(data.testResults) do
  --   local testFn = testResult.name
  --   for _, assertionResult in pairs(testResult.assertionResults) do
  --     local status, name = assertionResult.status, assertionResult.title
  --
  --     if name == nil then
  --       logger.error("Failed to find parsed test result ", assertionResult)
  --       return {}
  --     end
  --
  --     local keyid = testFn
  --
  --     for _, value in ipairs(assertionResult.ancestorTitles) do
  --       keyid = keyid .. "::" .. value
  --     end
  --
  --     keyid = keyid .. "::" .. name
  --
  --     if status == "pending" then
  --       status = "skipped"
  --     end
  --
  --     tests[keyid] = {
  --       status = status,
  --       short = name .. ": " .. status,
  --       output = consoleOut,
  --       location = assertionResult.location,
  --     }
  --
  --     if not vim.tbl_isempty(assertionResult.failureMessages) then
  --       local errors = {}
  --
  --       for i, failMessage in ipairs(assertionResult.failureMessages) do
  --         local msg = cleanAnsi(failMessage)
  --         local errorLine, errorColumn = findErrorPosition(testFn, msg)
  --
  --         errors[i] = {
  --           line = (errorLine or assertionResult.location.line) - 1,
  --           column = (errorColumn or 1) - 1,
  --           message = msg,
  --         }
  --
  --         tests[keyid].short = tests[keyid].short .. "\n" .. msg
  --       end
  --
  --       tests[keyid].errors = errors
  --     end
  --   end
  -- end

  return tests
end

return bun
