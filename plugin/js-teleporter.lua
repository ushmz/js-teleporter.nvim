if vim.g.loaded_jsteleporter == 1 then
  return
end
vim.g.loaded_jsteleporter = 1

vim.api.nvim_create_user_command("JSTeleporter", function(opts)
  require("js-teleporter").teleport()
end, {})
