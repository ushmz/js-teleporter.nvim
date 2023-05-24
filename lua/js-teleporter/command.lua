local _switch = {
  ["test"] = function(opts)
    require("js-teleporter").teleport("test", opts)
  end,
  ["story"] = function(opts)
    require("js-teleporter").teleport("story", opts)
  end,
}

local _switch_metatable = {
  __index = function(_, key)
    return function(_)
      vim.api.nvim_err_writeln("[JSTeleporter] Invalid command: " .. key)
    end
  end,
}

setmetatable(_switch, _switch_metatable)

local M = {}

M.command_list = function ()
  return vim.tbl_keys(_switch)
end

---Run plugin command
---@param args table
---args ={
--- "cmd": "test",
---}
M.run = function(args)
  local user_opts = args or {}
  if user_opts.cmd == nil then
    vim.api.nvim_err_writeln("[JSTeleporter] No command specified")
    return
  end

  _switch[user_opts.cmd](user_opts)
end

return M
