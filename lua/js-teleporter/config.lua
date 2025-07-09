_TeleporterConfigurationValues = _TeleporterConfigurationValues or {}

---@class TeleporterConfigObject
---@field set_options function
---@field context_roots function
---@field context_suffix function
---@field src_root function
---@field values TeleporterConfig
local config = {}
config.values = _TeleporterConfigurationValues

---@class TeleporterConfig
---@field source_root? string
---@field test_roots? Array<string>
---@field test_file_suffix? string
---@field story_roots? Array<string>
---@field story_file_suffix? string
---@field test_extensions? Array<string>
---@field story_extensions? Array<string>
---@field ignore_path? Array<string>

---@type TeleporterConfig
local teleporter_default = {
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

local first_non_nil = function(...)
  local n = select("#", ...)
  for i = 1, n do
    local value = select(i, ...)
    if value ~= nil then
      return value
    end
  end
end

---@param opts TeleporterConfig
config.set_options = function(opts)
  local get = function(name, default_value)
    return first_non_nil(opts[name], teleporter_default[name], default_value)
  end

  local set = function(name, default_value)
    config.values[name] = get(name, default_value)
  end

  for k, v in pairs(teleporter_default) do
    set(k, v)
  end

  local M = {}
  M.get = get
  return M
end

config.set_options({})

---@param self TeleporterConfigObject
---@return string
config.src_root = function(self)
  return self.values.source_root
end

---@param self TeleporterConfigObject
---@param context "test" | "story"
---@return Array<string>
config.context_roots = function(self, context)
  if context ~= "test" and context ~= "story" then
    require("js-teleporter.logger").print_err("Invalid context: " .. context)
    return {}
  end

  if context == "test" then
    return self.values.test_roots
  elseif context == "story" then
    return self.values.test_roots
  end

  return {}
end

---@param self TeleporterConfigObject
---@param context "test" | "story"
---@return string
config.context_suffix = function(self, context)
  if context ~= "test" and context ~= "story" then
    require("js-teleporter.logger").print_err("Invalid context: " .. context)
    return ""
  end

  if context == "test" then
    return self.values.test_file_suffix
  elseif context == "story" then
    return self.values.story_file_suffix
  end

  return ""
end

return config
