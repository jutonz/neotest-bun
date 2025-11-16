local xml2lua = require("neotest-bun.vendor.xml2lua.xml2lua")
local TreeHandler = require("neotest-bun.vendor.xml2lua.xmlhandler.tree")
-- local logger = require("neotest.logging")

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

-- convert `{ status = "failed" }` into `{ { status = "falied" } }` so it can
-- be passed into `ipairs`
function bun.ensureIsSequence(tableOrSequence)
  if type(tableOrSequence) == "table" and type(tableOrSequence[1]) ~= "table" then
    return { tableOrSequence }
  end

  return tableOrSequence
end

-- for a test with nested describe blocks like this:
--
-- ```js
-- describe("AppRoot", () => {
--   describe("when admin", () => {
--     it("renders")
--   })
-- })
-- ```
--
-- the reported classname from junit will look like this:
-- "when admin > AppRoot"
--
-- This function tranlates that to "AppRoot::when admin" so it matches how
-- neotest is expecting
function bun.parseClassname(classname)
  -- Handle both &gt; and > separators
  local separator = " &gt; "
  if not string.find(classname, separator) then
    separator = " > "
  end

  local testName = vim.split(classname, separator)
  local parsed

  if #testName > 1 then
    parsed = testName[#testName]
    for i = 1, #testName - 1 do
      parsed = parsed .. "::" .. testName[i]
    end
  else
    parsed = testName[1]
  end

  return parsed
end

function bun.xmlToResults(root, xml)
  local tests = {}

  local handler = TreeHandler:new()
  local parser = xml2lua.parser(handler)
  parser:parse(xml)

  -- Helper function to recursively process testsuites and extract testcases
  local function processTestsuite(testsuite)
    -- First, check if this testsuite has direct testcases
    if testsuite.testcase then
      local testcases = bun.ensureIsSequence(testsuite.testcase)
      for _, testcase in ipairs(testcases) do
        local attrs = testcase._attr
        local status

        if testcase.failure then
          status = "failed"
        elseif testcase.skipped then
          status = "skipped"
        else
          status = "passed"
        end

        local classname = bun.parseClassname(attrs.classname)
        local key = root .. "/" .. attrs.file .. "::"
        if classname ~= "" then
          key = key .. classname .. "::"
        end
        key = key .. attrs.name

        tests[key] = {
          status = status,
        }
      end
    end

    -- Then, check if this testsuite has nested testsuites
    if testsuite.testsuite then
      local nestedTestsuites = bun.ensureIsSequence(testsuite.testsuite)
      for _, nestedTestsuite in ipairs(nestedTestsuites) do
        processTestsuite(nestedTestsuite)
      end
    end
  end

  local testsuites = bun.ensureIsSequence(handler.root.testsuites.testsuite)
  for _, testsuite in ipairs(testsuites) do
    processTestsuite(testsuite)
  end

  return tests
end

return bun
