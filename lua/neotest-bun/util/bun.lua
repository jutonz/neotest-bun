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

return bun
