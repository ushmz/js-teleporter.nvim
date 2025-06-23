local M = {}

---Return if true the given file is a JS file
---@param context "test" | "story"
---@param filepath string
---@return boolean
function M.is_js_file(context, filepath)
  local extension = filepath:match(".*(%.[^.]+)$")
  if extension == nil then
    return false
  end

  ---@type TeleporterConfig
  local config = require("js-teleporter.config").values

  local extensions = {}
  if context == "test" then
    extensions = config.test_extensions
  elseif context == "story" then
    extensions = config.story_extensions
  end

  for _, v in ipairs(extensions) do
    if v == extension then
      return true
    end
  end
  return false
end

---Return if true the given file is the other context file
---@param context "test" | "story"
---@param filepath string
---@return boolean
function M.is_other_file(context, filepath)
  local basename = vim.fs.basename(filepath)
  local filename, extension = basename:match("(.*)(%.[^.]+)$")

  ---@type TeleporterConfig
  local config = require("js-teleporter.config").values

  local extensions = {}
  if context == "test" then
    extensions = config.test_extensions
  elseif context == "story" then
    extensions = config.story_extensions
  end

  if not vim.tbl_contains(extensions, extension) then
    return false
  end

  local suffix = ""
  if context == "test" then
    suffix = config.test_file_suffix
  elseif context == "story" then
    suffix = config.story_file_suffix
  end

  if not filename:match(suffix .. "$") then
    return false
  end

  return true
end

---@param filepath string
function M.new_file(filepath)
  if not filepath or filepath == "" then
    require("js-teleporter.logger").print_err("Please enter a valid file or folder name")
    return
  end

  if vim.fn.filereadable(filepath) == 1 then
    return filepath
  end

  if vim.fn.isdirectory(filepath) == 1 then
    vim.fn.mkdir(filepath, "p")
  else
    vim.fn.writefile({}, filepath, "a")
  end

  return filepath
end

return M
