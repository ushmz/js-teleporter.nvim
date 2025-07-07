local M = {}

function M.print_err(message)
  vim.api.nvim_echo({ { "[JSTeleporter] " .. message, "ErrorMsg" }, { "\n" } }, true, { err = true })
end

function M.print_msg(message)
  vim.api.nvim_echo({ { "[JSTeleporter] " .. message, "Normal" }, { "\n" } }, true, { err = false })
end

return M
