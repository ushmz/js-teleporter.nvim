-- src/path/to/file.ts <-> __tests__/path/to/file.test.ts

---@type TeleportStrategy
local RootDirectory = {
  to = function(context, path)
    return nil
  end,
  from = function(context, path)
    return nil
  end,
}
