local logger = require("js-teleporter.logger")

local M = {}

---Return true if the given file is a JS file
---@param context TeleporterContext
---@param filepath string
---@return boolean
function M.is_js_file(context, filepath)
  local config = require("js-teleporter.config")
  local extension = filepath:match(".*(%.[^.]+)$")
  if extension == nil then
    return false
  end

  local extensions = {}
  if context == "test" then
    extensions = config:context_extensions("test")
  elseif context == "story" then
    extensions = config:context_extensions("story")
  end

  for _, v in ipairs(extensions) do
    if v == extension then
      return true
    end
  end
  return false
end

---Return true if the given file is the other context file
---@param context TeleporterContext
---@param filepath string
---@return boolean
function M.is_other_file(context, filepath)
  local config = require("js-teleporter.config")
  local basename = vim.fs.basename(filepath)
  local filename, extension = basename:match("(.*)(%.[^.]+)$")

  local extensions = {}
  if context == "test" then
    extensions = config:context_extensions("test")
  elseif context == "story" then
    extensions = config:context_extensions("story")
  end

  if not vim.tbl_contains(extensions, extension) then
    return false
  end

  local suffix = ""
  if context == "test" then
    suffix = config:context_suffix("test")
  elseif context == "story" then
    suffix = config:context_suffix("story")
  end

  if not filename:match(suffix .. "$") then
    return false
  end

  return true
end

---@param filepath string
function M.new_file(filepath)
  if not filepath or filepath == "" then
    logger.print_err("Please enter a valid file or folder name")
    return
  end

  if vim.fn.filereadable(filepath) == 1 then
    return filepath
  end

  local dir_path = vim.fn.fnamemodify(filepath, ":h")
  if vim.fn.isdirectory(dir_path) == 0 then
    vim.fn.mkdir(dir_path, "p")
  end

  vim.fn.writefile({}, filepath, "a")

  return filepath
end

return M
