---@class TeleportContext
---@field suffix string
---@field markers string[]

---@class TeleportStrategy
---@field to fun(context: TeleportContext, path: string): string | nil
---@field from fun(context: TeleportContext, path: string): string | nil
