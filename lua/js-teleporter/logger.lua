local M = {}

function M.print_err(message)
  vim.api.nvim_echo({ "[JSTeleporter] " .. message, "ErrorMsg" }, true, { err = true })
end

function M.print_msg(message)
  vim.api.nvim_echo({ "[JSTeleporter] " .. message, "Normal" }, true, { err = false })
end

return M
