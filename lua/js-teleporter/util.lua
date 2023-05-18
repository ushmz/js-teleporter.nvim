local M = {}

M.get_os_sep = function()
  return require("plenary.path").path.sep
end

---Return extensions of given file
---@param file string
---@return string
M.get_extension = function(file)
  local ext = file:match("^.+(%..+)$")
  return ext
end

---Return filename of given file
---@param file string
---@return string
M.get_basename = function(file)
  local parts = {}
  for part in file:gmatch("[^%.]+") do
    table.insert(parts, part)
  end
  table.remove(parts)
  return table.concat(parts, ".")
end

---@return boolean
M.is_dir = function(path)
  if require("plenary.path").is_path(path) then
    return require("plenary.path").is_dir(path)
  end
  return require("plenary.path"):new(path):is_dir()
end

---@param dir1 string
---@param dir2 string
---@return boolean
M.is_same_dir = function(dir1, dir2)
  local stat1 = vim.loop.fs_stat(dir1)
  local stat2 = vim.loop.fs_stat(dir2)
  if stat1 and stat2 and stat1.type == "directory" and stat2.type == "directory" then
    return stat1.dev == stat2.dev and stat1.ino == stat2.ino
  else
    return false
  end
end

---@param dir string
---@return table
M.scan_dir = function(dir)
  return require("plenary.scandir").scan_dir(dir, { only_dirs = true, depth = 1 })
end

---@param filepath string
---@return boolean
M.exists = function(filepath)
  -- [TODO] This puts error message, suppress message and go through
  -- require("plenary.path").exists(filepath)
  local f = io.open(filepath, "r")
  if f == nil then
    return false
  end
  io.close(f)
  return true
end

---Open file with current buffer
---@param path string
M.open_file = function(path)
  vim.loop.fs_open(path, "a", 438)
end

---Create new file with given path
---@param filepath string
M.create_file = function(filepath)
  if not filepath then
    return
  end

  if filepath == "" then
    vim.api.nvim_err_writeln("Please enter a valid file or folder name")
    return
  end

  local path = require("plenary.path"):new(filepath)
  if M.exists(path.filename) then
    vim.api.nvim_err_writeln("File already exists")
    return
  end

  if M.is_dir(path.filename) then
    path:touch({ parents = true })
  else
    require("plenary.path"):new(path.filename:sub(1, -2)):mkdir({ parents = true })
  end
  return path
end

---Get filename on current buffer. Return empty ("") if current buffer is empty.
---@return string | nil
M.get_filename_on_current_buffer = function()
  local bufnr = vim.api.nvim_get_current_buf()
  if not bufnr then
    return
  end
  return vim.api.nvim_buf_get_name(bufnr)
end

---@param target string
---@param splitter string
---@return string[]
M.split = function(target, splitter)
  local parts = {}
  for part in string.gmatch(target, "([^" .. splitter .. "]+)") do
    table.insert(parts, part)
  end
  return parts
end

return M
