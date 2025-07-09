---@alias TeleporterContext "test" | "story"

---@class TeleporterConfigObject
---@field setup function(opts: TeleporterConfig?): void
---@field src_root function(self): string
---@field context_roots function(self, context: TeleporterContext): Array<string>
---@field context_suffix function(self, context: TeleporterContext): string
---@field context_extensions function(self, context: TeleporterContext): Array<string>
---@field _options TeleporterConfig

local M = {}

---@class TeleporterConfig
---@field source_root string
---@field test_roots Array<string>
---@field test_file_suffix string
---@field story_roots Array<string>
---@field story_file_suffix string
---@field test_extensions Array<string>
---@field story_extensions Array<string>
---@field ignore_path Array<string>

---@type TeleporterConfig
local _default = {
  -- Root directory of source.
  source_root = "src",
  -- Root directories of tests.
  -- Files under configured directories are considered tests.
  test_roots = { "__tests__" },
  -- Suffix to determine if the file is a test.
  test_file_suffix = ".test",
  -- Root directories of storybook.
  -- Files under configured directories are considered storybook.
  story_roots = { "stories" },
  -- Suffix to determine if the file is a storybook.
  story_file_suffix = ".stories",
  -- Extensions to determine if the file is a test file.
  test_extensions = { ".ts", ".js", ".tsx", ".jsx", ".mts", ".mjs", ".cts", ".cjs" },
  -- Extensions to determine if the file is a storybook.
  story_extensions = { ".tsx", ".jsx" },
  -- Files in these directories are ignored
  ignore_path = { "node_modules" },
}

---@class TeleporterConfigOptions
---@field source_root? string
---@field test_roots? Array<string>
---@field test_file_suffix? string
---@field story_roots? Array<string>
---@field story_file_suffix? string
---@field test_extensions? Array<string>
---@field story_extensions? Array<string>
---@field ignore_path? Array<string>

---@param opts? TeleporterConfigOptions
M.setup = function(opts)
  if vim.fn.has("nvim-0.11") == 1 then
    vim.validate("opts", opts, "table", true)
  else
    vim.validate({opts = { opts, "table", true }})
  end

  opts = opts or {}

  local merged = vim.tbl_deep_extend("force", _default, opts)

  M._options = merged
end

---@param self TeleporterConfigObject
---@return string
M.src_root = function(self)
  return self._options.source_root or ""
end

---@param self TeleporterConfigObject
---@param context TeleporterContext
---@return Array<string>
M.context_roots = function(self, context)
  if context ~= "test" and context ~= "story" then
    require("js-teleporter.logger").print_err("Invalid context: " .. context)
    return {}
  end

  if context == "test" then
    return self._options.test_roots
  elseif context == "story" then
    return self._options.test_roots
  end

  return {}
end

---@param self TeleporterConfigObject
---@param context TeleporterContext
---@return string
M.context_suffix = function(self, context)
  if context ~= "test" and context ~= "story" then
    require("js-teleporter.logger").print_err("Invalid context: " .. context)
    return ""
  end

  if context == "test" then
    return self._options.test_file_suffix
  elseif context == "story" then
    return self._options.story_file_suffix
  end

  return ""
end

M.context_extensions = function(self, context)
  if context ~= "test" and context ~= "story" then
    require("js-teleporter.logger").print_err("Invalid context: " .. context)
    return {}
  end

  if context == "test" then
    return self._options.test_extensions
  elseif context == "story" then
    return self._options.story_extensions
  end

  return {}
end

return M
