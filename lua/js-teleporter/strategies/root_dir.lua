---@type TeleportStrategy
local RootDirectory = {
  --- Calculates the target file path by transforming a test/storybook file path
  --- back to its original source file path.
  --- It returns the full path if the resulting source file exists and is readable, otherwise `nil`.
  ---
  --- Example:
  ---
  --- ```lua
  --- local context = { suffix = ".test", markers = { "__tests__" }, root = "src" }
  --- local path = "my_project/__tests__/utils/index.test.ts"
  ---
  --- -- It will attempt to find "my_project/src/utils/"
  --- -- If it exists, return "my_project/src/utils/index.ts" regardless its existence.
  --- require("js-teleporter.strategy.root_dir").from(context, path)
  --- ```
  from = function(context, path)
    ---@type string, string, string
    local dir, filename, extension = path:match("(.*)/([^/]+)%.([^.]+)$")
    if not dir or not filename or not extension then
      return nil
    end

    local suffix = context.suffix or ""
    local target_filename, count = filename:gsub(suffix .. "$", "", 1)
    if count < 1 then
      return nil
    end

    for _, marker in ipairs(context.markers) do
      local target_dir, cnt = dir:gsub("(/?)" .. marker .. "(/?)", "%1" .. context.root .. "%2", 1)
      if cnt == 1 and vim.fn.isdirectory(target_dir) == 1 then
        return vim.fs.joinpath(target_dir, target_filename .. "." .. extension)
      end
    end

    return nil
  end,
  --- Calculates the target file path by transforming a source file path
  --- to its corresponding test or storybook file path.
  --- It iterates through `context.markers` and returns the first existing and readable target file.
  ---
  --- Example:
  ---
  --- ```lua
  --- local context = { suffix = ".test", markers = { "__tests__", "spec" } }
  --- local path = "my_project/src/utils/index.ts"
  ---
  --- -- It will first attempt to find "my_project/__tests__/utils/" directory.
  --- -- If it exists, return "my_project/__tests__/utils/index${suffix}.ts" regardless its existence.
  --- -- If not found, it might then (if markers contains it) attempt to find "my_project/spec/utils/"
  --- require("js-teleporter.strategy.root_dir").to(context, path)
  --- ```
  to = function(context, path)
    ---@type string, string, string
    local dir, filename, extension = path:match("(.*)/([^/]+)%.([^.]+)$")
    if not dir or not filename or not extension then
      return nil
    end

    local target_filename = filename .. context.suffix

    for _, marker in ipairs(context.markers) do
      local target_dir, count = dir:gsub("(.*)/" .. context.root, "%1/" .. marker, 1)
      if count > 0 and vim.fn.isdirectory(target_dir) == 1 then
        return vim.fs.joinpath(target_dir, target_filename .. "." .. extension)
      end
    end

    return nil
  end,
}

return RootDirectory
