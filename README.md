# neotest-bun

A [neotest] adapter for [bun test], very much inspired by [neotest-jest].

[neotest]: https://github.com/nvim-neotest/neotest
[bun test]: https://bun.sh/docs/cli/test
[neotest-jest]: https://github.com/nvim-neotest/neotest-jest

## Installation

Add `"jutonz/neotest-bun"` to your plugin manager of choice.

e.g. with [lazy.nvim]:

```lua
{
  "nvim-neotest/neotest",
  dependencies = {
    "jutonz/neotest-bun",
    -- ... other dependencies ...
  },
  -- ... other config ..
}
```

Tell neotest about this adapter when you call `setup`

```lua
require("neotest").setup({
  adapters = {
    require("neotest-bun"),
    -- ... other adapters ...
  },
  -- ... other config ...
})
```

[lazy.nvim]: https://github.com/folke/lazy.nvim

## Configuration

You can pass in config options when requiring the adapter.

```lua
require("neotest-bun")({
  additional_args = { "--coverage" },
})
```

Here are the defaults:

```lua
{
  test_command = "bun test",
  additional_args = {},
}
```
