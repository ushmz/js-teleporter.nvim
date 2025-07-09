local logger = require("js-teleporter.logger")

local M = {}

---Return true if the given file is a JS file
---@param context "test" | "story"
---@param filepath string
---@param opts TeleporterConfig
---@return boolean
function M.is_js_file(context, filepath, opts)
  local extension = filepath:match(".*(%.[^.]+)$")
  if extension == nil then
    return false
  end

  local extensions = {}
  if context == "test" then
    extensions = opts.test_extensions
  elseif context == "story" then
    extensions = opts.story_extensions
  end

  for _, v in ipairs(extensions) do
    if v == extension then
      return true
    end
  end
  return false
end

---Return true if the given file is the other context file
---@param context "test" | "story"
---@param filepath string
---@param opts TeleporterConfig
---@return boolean
function M.is_other_file(context, filepath, opts)
  local basename = vim.fs.basename(filepath)
  local filename, extension = basename:match("(.*)(%.[^.]+)$")

  local extensions = {}
  if context == "test" then
    extensions = opts.test_extensions
  elseif context == "story" then
    extensions = opts.story_extensions
  end

  if not vim.tbl_contains(extensions, extension) then
    return false
  end

  local suffix = ""
  if context == "test" then
    suffix = opts.test_file_suffix
  elseif context == "story" then
    suffix = opts.story_file_suffix
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
