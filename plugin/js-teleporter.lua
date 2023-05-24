if vim.g.loaded_jsteleporter == 1 then
  return
end
vim.g.loaded_jsteleporter = 1

vim.api.nvim_create_user_command("JSTeleporter", function(opts)
  require("js-teleporter.command").run({ cmd = opts.fargs[1], args = opts.fargs })
end, {
  range = true,
  nargs = "+",
  complete = function(arg)
    local list = require("js-teleporter.command").command_list()
    return vim.tbl_filter(function(s)
      return string.match(s, "^" .. arg)
    end, list)
  end,
})
