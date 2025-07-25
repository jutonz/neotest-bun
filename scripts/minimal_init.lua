-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
-- local lazypath = "/Users/jutonz/code/jutonz/neotest-bun/tmp/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out =
    vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Setup lazy.nvim
require("lazy").setup({
  spec = {
    {
      "nvim-neotest/neotest",
      dependencies = {
        "nvim-neotest/nvim-nio",
        "nvim-lua/plenary.nvim",
        "antoinemadec/FixCursorHold.nvim",
        "nvim-treesitter/nvim-treesitter",
      },
    },
    { "echasnovski/mini.nvim", version = "*" },
    { dir = ".", build = false },
  },
  install = { colorscheme = { "habamax" } },
})

-- Only install plugins if this isn't a test child process
if not vim.env.NVIM then
  require("lazy").install({ wait = true })

  -- Install xml2lua dependency manually since lazy.nvim's luarocks has issues
  local lazy_rocks_path = vim.fn.stdpath("data") .. "/lazy-rocks/_"
  vim.fn.system({"luarocks", "--tree=" .. lazy_rocks_path, "install", "xml2lua"})
end

-- Add current directory to 'runtimepath' to be able to use 'lua' files
vim.cmd([[let &rtp.=','.getcwd()]])

-- Set up 'mini.test' and 'mini.doc' only when calling headless Neovim (like with `make test` or `make documentation`)
if #vim.api.nvim_list_uis() == 0 then
  -- Add deps to 'runtimepath' to be able to use in child nvim instance
  -- vim.cmd("set rtp+=deps/mini.nvim")
  -- vim.cmd("set rtp+=deps/neotest")
  -- vim.cmd("set rtp+=deps/xml2lua/lua")

  -- Set up 'mini.test'
  require("mini.test").setup()

  -- Set up 'mini.doc'
  require("mini.doc").setup()
end
