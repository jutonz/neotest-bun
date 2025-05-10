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
{ "jutonz/neotest-bun" },
```

Because this plugin has some lua dependencies, you'll also need lua 5.1
installed on your computer. This is easiest to do by adding `lua 5.1` to your
`.tool-versions` file if you're using asdf or mise.

[lazy.nvim]: https://github.com/folke/lazy.nvim

