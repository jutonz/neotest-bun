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
  return s
  -- return (
  --   s:gsub("%(", "%\\(")
  --     :gsub("%)", "%\\)")
  --     :gsub("%]", "%\\]")
  --     :gsub("%[", "%\\[")
  --     :gsub("%*", "%\\*")
  --     :gsub("%+", "%\\+")
  --     :gsub("%-", "%\\-")
  --     :gsub("%?", "%\\?")
  --     :gsub("%$", "%\\$")
  --     :gsub("%^", "%\\^")
  --     :gsub("%/", "%\\/")
  --     :gsub("%'", "%\\'")
  -- )
end

function bun.parsedJsonToResults(data, output_file, consoleOut)
  local tests = {}

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
