local util = require("js-teleporter.util")

---@type TeleportStrategy
local RootDirectory = {
  filetype = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
  --- Calculates the target file path by transforming a test/storybook file path back to its original source file path.
  --- It identifies the special marker directory (e.g., '__tests__') relative to the project root,
  --- replaces it with the main source directory name (e.g., 'src'), and removes a suffix from the filename.
  --- It returns the full path if the resulting target directory exists, otherwise `nil`.
  --- The existence of the file itself is not checked.
  ---
  --- Example:
  ---
  --- ```lua
  --- local context = { suffix = ".test", markers = { "__tests__" }, root = "src" }
  --- local path = "my_project/__tests__/utils/index.test.ts"
  ---
  --- -- It will attempt to find "my_project/src/utils/".
  --- -- If this directory exists, it returns "my_project/src/utils/index.ts".
  --- require("js-teleporter.strategy.root_dir").from(context, path)
  --- ```
  from = function(context, path)
    ---@type string, string, string
    local dir, filename, extension = path:match("(.*)/([^/]+)%.([^.]+)$")
    if not dir or not filename or not extension then
      return nil
    end

    local suffix = context.suffix or ""
    local target_filename, count = filename:gsub(vim.pesc(suffix) .. "$", "", 1)
    if count < 1 then
      return nil
    end

    for _, marker in ipairs(context.markers) do
      local target_dir, cnt = dir:gsub("(/?)" .. vim.pesc(marker) .. "(/?)", "%1" .. vim.pesc(context.root) .. "%2", 1)
      if cnt == 1 and vim.fn.isdirectory(target_dir) == 1 then
        return util.joinpath(target_dir, target_filename .. "." .. extension)
      end
    end

    return nil
  end,
  --- Calculates the target file path by transforming a source file path to its corresponding test or storybook file path.
  --- It replaces the main source directory (e.g., 'src') with one of the `context.markers` (e.g., '__tests__'),
  --- and adds a suffix to the filename. It iterates through `context.markers` and returns the first target file path
  --- whose parent directory exists. The existence of the file itself is not checked.
  ---
  --- Example:
  ---
  --- ```lua
  --- local context = { suffix = ".test", markers = { "__tests__", "spec" }, root = "src" }
  --- local path = "my_project/src/utils/index.ts"
  ---
  --- -- It will first attempt to find "my_project/__tests__/utils/" directory.
  --- -- If it exists, it returns "my_project/__tests__/utils/index.test.ts".
  --- -- If not found, it might then attempt to find "my_project/spec/utils/" directory.
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
      ---@type string, string
      local leading_seg, tailing_seg = dir:match("(.*/?)" .. vim.pesc(context.root) .. "(/?.*)", 1)

      local context_root_path = (leading_seg or "") .. marker
      local parent_dir = context_root_path .. (tailing_seg or "")

      if vim.fn.isdirectory(context_root_path) == 1 then
        return util.joinpath(parent_dir, target_filename .. "." .. extension)
      end
    end

    return nil
  end,
}

return RootDirectory
