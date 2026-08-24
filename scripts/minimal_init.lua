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

-- Get absolute path to plugin root
local script_path = debug.getinfo(1, "S").source:sub(2)
local plugin_root = vim.fn.fnamemodify(script_path, ":p:h:h")

-- Setup lazy.nvim
require("lazy").setup({
  spec = {
    {
      "nvim-neotest/neotest",
      dependencies = {
        "nvim-neotest/nvim-nio",
        "nvim-lua/plenary.nvim",
        "antoinemadec/FixCursorHold.nvim",
      },
    },
    -- Not a neotest dependency: this is here only to compile the parsers the
    -- adapter's queries need. Requires nvim 0.12+, tree-sitter-cli and a C
    -- compiler. `build` is off because `:TSUpdate` is fire-and-forget and
    -- would race the awaited install below.
    {
      "nvim-treesitter/nvim-treesitter",
      branch = "main",
      lazy = false,
      build = false,
    },
    {
      "echasnovski/mini.nvim",
      -- Removing version temporarily to get `ignore_attr` and `ignore_text`
      -- options to `reference_screenshot`.
      -- Add this back once mini.nvim 0.17 is released.
      -- version = "*"
    },
    { dir = plugin_root },
  },
  rocks = {
    hererocks = false,
    enabled = false,
  },
  install = { colorscheme = { "habamax" } },
})

require("lazy").install({ wait = true })

local function install_parsers()
  -- Only advances while the event loop runs, so it must be waited on. Reports a
  -- failed download or compile by returning false, and raises only on timeout.
  local ok, installed = pcall(function()
    return require("nvim-treesitter").install({ "typescript", "javascript" }):wait(120000)
  end)

  if not ok or installed == false then
    io.stderr:write("failed to install treesitter parsers: " .. tostring(installed) .. "\n")
    os.exit(1)
  end
end

if vim.env.NEOTEST_BUN_SKIP_PARSERS ~= "1" then
  install_parsers()
end

vim.opt.swapfile = false
vim.o.statusline = "%<%f %l,%c%V"

-- Update runtimepath so lua files can be required in tests.
vim.opt.rtp:append(plugin_root)

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
