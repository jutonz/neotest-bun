-- You can use this loaded variable to enable conditional parts of your plugin.
if _G.NeotestBunLoaded then
  return
end

_G.NeotestBunLoaded = true

-- Useful if you want your plugin to be compatible with older (<0.7) neovim versions
if vim.fn.has("nvim-0.7") == 0 then
  vim.cmd("command! NeotestBun lua require('neotest-bun').toggle()")
else
  vim.api.nvim_create_user_command("NeotestBun", function()
    require("neotest-bun").toggle()
  end, {})
end
