-- src/path/to/file.ts <-> src/path/to/file.test.ts

---@type TeleportStrategy
local SameDirectory = {
  --- Calculates the target file path by removing a specified suffix from the current filename
  --- within the same directory. It returns the full path if the resulting file exists and is
  --- readable, otherwise `nil`.
  ---
  --- @example
  --- -- Given context.suffix = ".test", path = "/src/components/button.test.ts"
  --- -- It will attempt to find "/src/components/button.ts"
  --- --
  --- -- Given context.suffix = ".stories", path = "/src/components/icon.stories.tsx"
  --- -- It will attempt to find "/src/components/icon.tsx"
  from = function(context, path)
    local dir, filename, extension = path:match("(.*)/([^/]+)%.([^.]+)$")
    if not dir or not filename or not extension then
      return nil
    end

    local target_filename = filename:gsub(context.suffix .. "$", "")

    local target_filepath = vim.fs.joinpath(dir, target_filename .. "." .. extension)

    return target_filepath
  end,
  --- Calculates the target file path by adding a specified suffix to the current filename
  --- within the same directory. It returns the full path if the resulting file exists and
  --- is readable, otherwise `nil`.
  ---
  --- @example
  --- -- Given context.suffix = ".test", path = "/src/components/button.ts"
  --- -- It will attempt to find "/src/components/button.test.ts"
  --- --
  --- -- Given context.suffix = ".stories", path = "/src/components/icon.tsx"
  --- -- It will attempt to find "/src/components/icon.stories.tsx"
  to = function(context, path)
    local dir, filename, extension = path:match("(.*)/([^/]+)%.([^.]+)$")
    if not dir or not filename or not extension then
      return nil
    end

    local target_filepath = vim.fs.joinpath(dir, filename .. context.suffix .. "." .. extension)

    return target_filepath
  end,
}

return SameDirectory
