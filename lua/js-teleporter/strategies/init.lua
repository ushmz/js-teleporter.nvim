---@class TeleportContext
---@field suffix string
---@field markers string[]
---@field root string
---@filed filetype? string

---@class TeleportStrategy
---@field to fun(context: TeleportContext, path: string): string | nil
---@field from fun(context: TeleportContext, path: string): string | nil
---@field filetype string[]

local M = {}

---@param filetype string
---@return TeleportStrategy[]
M.ft_strategies = function(filetype)
  local strategies = {
    require("js-teleporter.strategies.nearest_parent_dir"),
    require("js-teleporter.strategies.root_dir"),
    require("js-teleporter.strategies.same_dir"),
  }

  return vim.tbl_filter(function(strategy)
    return strategy.filetype == "*" or vim.tbl_contains(strategy.filetype, filetype)
  end, strategies)
end

return M
