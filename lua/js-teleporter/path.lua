local M = {}

M._path = require("plenary.path")
M.sep = M._path.path.sep
M.root = M._path.path.root()

---Extract filename from filepath
---@param filepath string
---@return string
function M.filename(filepath)
  local parts = {}
  for part in filepath:gmatch("[^%" .. M.sep .. "]+") do
    table.insert(parts, part)
  end
  return table.remove(parts)
end

---Extract basename from filepath
---@param filepath string
---@return string
function M.basename(filepath)
  local file = M.filename(filepath)

  local parts = {}
  for part in file:gmatch("[^%.]+") do
    table.insert(parts, part)
  end
  table.remove(parts)
  return table.concat(parts, ".")
end

---Extract extension of given file
---@param file string
---@return string
function M.extension(file)
  return file:match("^.+(%..+)$")
end

---Extract parent directory path from given filepath
---@param filepath string
---@return string
function M.parent_dir(filepath)
  local parent = M._path:new(filepath):parent()
  return parent.filename
end

---Return if given filepath is directory
---@param filepath string
---@return boolean
function M.is_dir(filepath)
  return M._path:new(filepath):is_dir()
end

---Return if given 2 paths indicate same directory
---@param dir1 string
---@param dir2 string
---@return boolean
function M.is_same_dir(dir1, dir2)
  local stat1 = vim.loop.fs_stat(dir1)
  local stat2 = vim.loop.fs_stat(dir2)
  if stat1 and stat2 and stat1.type == "directory" and stat2.type == "directory" then
    return stat1.dev == stat2.dev and stat1.ino == stat2.ino
  else
    return false
  end
end

function M.join_path(base, ...)
  -- NOTE: Do the same thing with `require("plenary.path").path:new():joinpath(base, ...)`
  local path = M._path:new(base, ...)
  return path.filename
end

---Get list of directory which is located in given directory
---@param parent string
---@return table
function M.list_dir(parent)
  return require("plenary.scandir").scan_dir(parent, { only_dirs = true, depth = 1 })
end

---Return if given filepath exists
---@param filepath string
---@return boolean
function M.exists(filepath)
  return M._path:new(filepath):exists()
end

---Split given charactors by given splitter
---@param target string
---@param splitter string
---@return table
function M.split(target, splitter)
  local parts = {}
  for part in string.gmatch(target, "([^" .. splitter .. "]+)") do
    table.insert(parts, part)
  end
  return parts
end

---Trim unmatched child path from given base path
---e.g. base: /a/b/c/d, comparison: /a/b/c/e/f -> /a/b/c
---@param base string
---@param comparison string
---@return string
function M.trim_unmatched_child_path(base, comparison)
  if base == "" then
    return ""
  end

  if comparison == "" then
    return base
  end

  local base_elements = M.split(base, M.sep)
  local comparison_elements = M.split(comparison, M.sep)

  local match_index = 0
  for i, v in ipairs(base_elements) do
    local amount = comparison_elements[i]
    if v ~= amount then
      match_index = i
      break
    end
  end

  return table.concat(base_elements, M.sep, match_index)
end

return M
