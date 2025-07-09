local u = require("js-teleporter.util")

---@type TeleportStrategy
local NearestParentDirectory = {
  --- Calculates the target file path by transforming a test/storybook file path
  --- back to its original source file path.
  --- It returns the full path if the resulting source file exists and is readable, otherwise `nil`.
  ---
  --- Example:
  ---
  --- ```lua
  --- local context = { suffix = ".test", markers = { "__tests__" } }
  --- local path = "my_project/__tests__/utils/math.test.ts"
  --- -- It will attempt to find "/my_project/utils/math.ts"
  --- require("js-teleporter.strategy.nearest-parent-directory").from(context, path)
  --- ```
  from = function(context, path)
    local dir, filename, extension = path:match("(.*)/([^/]+)%.([^.]+)$")
    if not dir or not filename or not extension then
      return nil
    end

    local target_filename = filename:gsub(context.suffix, "")

    local target_dir = dir
    for _, marker in ipairs(context.markers) do
      target_dir = target_dir:gsub(marker .. "/?", "")
    end

    local target_filepath = vim.fs.joinpath(target_dir, target_filename .. "." .. extension)

    return target_filepath
  end,
  ---Calculates the target file path by transforming a source file path
  ---to its corresponding test or storybook file path.
  ---It iterates through `context.markers` and returns the first existing and readable target file.
  ---
  --- Example:
  ---
  --- ```lua
  --- local context = { suffix = ".test", markers = { "__tests__", "spec" } }
  --- local path = "my_project/src/utils/math.ts", it will first attempt to find
  --- -- It will firat attempt to find "my_project/src/utils/__tests__/math.test.ts" > "my_project/src/__tests__/utils/math.test.ts" ...
  --- -- If not found, it might then (if markers contains it) attempt to find "my_project/utils/spec/math.test.ts" ...
  --- require("js-teleporter.strategy.nearest-parent-directory").to(context, path)
  --- ```
  to = function(context, path)
    local dir, filename, extension = path:match("(.*)/([^/]+)%.([^.]+)$")
    if not dir or not filename or not extension then
      return nil
    end

    for _, marker in ipairs(context.markers) do
      local root_dir = vim.fs.root(path, marker)
      if root_dir and vim.fn.isdirectory(vim.fs.joinpath(root_dir, marker)) == 1 then
        if dir == root_dir then
          return vim.fs.joinpath(root_dir, marker, filename .. context.suffix .. "." .. extension)
        end

        local breadcrumb = u.get_path_difference(dir, root_dir .. "/")
        return vim.fs.joinpath(root_dir, marker, breadcrumb, filename .. context.suffix .. "." .. extension)
      end
    end

    return nil
  end,
}

return NearestParentDirectory
