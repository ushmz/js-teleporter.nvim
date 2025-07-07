local logger = require("js-teleporter.logger")

local M = {}

--- Extracts the difference part of a full path relative to a base path.
--- This function assumes 'base_path' is a directory prefix (or the full path itself)
--- and handles common path separators.
--- @param full_path string # The full path (e.g., "/home/user/documents/file.txt").
--- @param base_path string # The base path to compare against (e.g., "/home/user/documents").
--- @return string # The relative path difference (e.g., "file.txt"), or "" if paths are identical,
---                  or the original full_path if base_path is not a prefix.
--- @example
--- -- Assuming base_path is "/project/root"
--- get_path_difference("/project/root/src/main.js", "/project/root") -- returns "src/main.js"
--- get_path_difference("/project/root/file.txt", "/project/root/file.txt") -- returns ""
--- get_path_difference("/another/dir/file.c", "/project/root") -- returns "/another/dir/file.c" (base_path is not a prefix)
function M.get_path_difference(full_path, base_path)
  local os_sep = jit.os:match("Windows") and "\\" or "/"

  local norm_full = full_path:gsub("[\\/]", os_sep)
  local norm_base = base_path:gsub("[\\/]", os_sep)

  if #norm_base == 0 or norm_base == os_sep then
    return full_path
  end

  if vim.fn.isdirectory(norm_base) == 0 then
    logger.print_err("Base path should be a directory: " .. norm_base)
    return ""
  end

  if norm_full:sub(1, #norm_base) == norm_base then
    if #norm_full == #norm_base then
      return ""
    end

    local diff = norm_full:sub(#norm_base + 1)
    if #diff > 0 and diff:sub(1, 1) == os_sep then
      diff = diff:sub(2)
    end

    return diff
  end

  return full_path
end

return M
