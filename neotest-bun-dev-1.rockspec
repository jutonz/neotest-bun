package = "neotest-bun"
version = "dev-1"
source = {
   url = "git+ssh://git@github.com/shortcuts/neovim-plugin-boilerplate.git"
}
description = {
   summary = "<p align=\"center\">     Plug and play Neovim plugin boilerplate with pre-configured CI, CD, linter, docs and tests.",
   detailed = [[
<p align="center">
    Plug and play Neovim plugin boilerplate with pre-configured CI, CD, linter, docs and tests.
</p>]],
   homepage = "*** please enter a project homepage ***",
   license = "*** please specify a license ***"
}
dependencies = {
   "lua ~> 5.1",
  "xml2lua",
}
build = {
   type = "builtin",
   modules = {
      ["neotest-bun.config"] = "lua/neotest-bun/config.lua",
      ["neotest-bun.init"] = "lua/neotest-bun/init.lua",
      ["neotest-bun.main"] = "lua/neotest-bun/main.lua",
      ["neotest-bun.state"] = "lua/neotest-bun/state.lua",
      ["neotest-bun.util.bun"] = "lua/neotest-bun/util/bun.lua",
      ["neotest-bun.util.log"] = "lua/neotest-bun/util/log.lua"
   },
   copy_directories = {
      "doc",
      "tests"
   }
}
