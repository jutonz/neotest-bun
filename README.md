# neotest-bun

A [neotest] adapter for [bun test], very much inspired by [neotest-jest].

**Status**: This is very early on in its development. Give it a try if you
want, but please expect some rough edges.

[neotest]: https://github.com/nvim-neotest/neotest
[bun test]: https://bun.sh/docs/cli/test
[neotest-jest]: https://github.com/nvim-neotest/neotest-jest

## Installation

The only plugin manager I've tested this with is [lazy.nvim]. This plugin
requires some lua dependencies to be installed via luarocks (lua's package
manager, like `bundle` or `npm`). I know that lazy.nvim can do that, but I'm
not sure about other plugin managers.

```lua
require("lazy").setup({ "jutonz/neotest-bun" })
```

[lazy.nvim]: https://github.com/folke/lazy.nvim

