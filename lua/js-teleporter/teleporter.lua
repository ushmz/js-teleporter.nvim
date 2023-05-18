local util = require("js-teleporter.util")
local Path = require("plenary.path")

local Teleporter = {}

local get_config = function()
  return require("js-teleporter.config").values
end

---Get roots in the context
---@param context "test" | "story"
---@return table
local roots_in_context = function(context)
  local conf = get_config()
  local roots = {}
  if context == "test" then
    roots = conf.test_source_roots
  elseif context == "story" then
    roots = conf.storybook_source_roots
  end

  return roots
end

---Get extensions in the context
---@param context "test" | "story"
---@return table
local extensions_in_context = function(context)
  local conf = get_config()

  local extensions = {}
  if context == "test" then
    extensions = conf.extensions_for_test
  elseif context == "story" then
    extensions = conf.extensions_for_storybook
  end

  return extensions
end

---Get suffix in the context
---@param context "test" | "story"
---@return string
local suffix_in_context = function(context)
  local conf = get_config()

  local suffix = ""
  if context == "test" then
    suffix = conf.test_file_suffix
  elseif context == "story" then
    suffix = conf.storybook_file_suffix
  end

  return suffix
end

---@param context "test" | "story"
---@param current_dir Path
---@return string | nil
local find_other_context_root_dir_name = function(context, current_dir)
  if not current_dir:is_dir() then
    return
  end

  -- NOTE : `util.scan_dir()` returns only directories
  local dirs = util.scan_dir(current_dir.filename)
  for _, file in ipairs(dirs) do
    for _, v in ipairs(roots_in_context(context)) do
      if current_dir .. util.get_os_sep() .. v == file then
        return v
      end
    end
  end
end

---Teleport to other file
---@param context "test" | "story"
---@param filename string
---@param workspace_path string
Teleporter.teleport_to = function(context, filename, workspace_path)
  if not Teleporter.is_js_file(context, filename) then
    vim.api.nvim_err_writeln("[JSTeleporter] The file is not javascript/typescript. file: " .. filename)
    return
  end

  if Teleporter.is_other_context_file(context, filename) then
    return Teleporter.from_other_context(context, filename, workspace_path)
  else
    return Teleporter.to_other_context(context, filename, workspace_path)
  end
end

---Return true if the other context file is opened in current buffer
---@param context "test" | "story"
---@param filepath string
---@return boolean
Teleporter.is_in_context = function(context, filepath)
  local sep = util.get_os_sep()

  for _, v in ipairs(roots_in_context(context)) do
    --TODO: filepath:match("[/^]..v..[/$]") doesn't work as expected
    if filepath:match(sep .. v .. sep) then
      return true
    end
    if filepath:match("^" .. v .. sep) then
      return true
    end
    if filepath:match(sep .. v .. "$") then
      return true
    end
    if filepath:match("^" .. v .. "$") then
      return true
    end
  end
  return false
end

---Return if true the given file is a JS file
---@param context "test" | "story"
---@param filename string
---@return boolean
Teleporter.is_js_file = function(context, filename)
  local ext = util.get_extension(filename)
  for _, v in ipairs(extensions_in_context(context)) do
    if v == ext then
      return true
    end
  end
  return false
end

---Return if true the given file is the other context file
---@param context "test" | "story"
---@param filename string
---@return boolean
Teleporter.is_other_context_file = function(context, filename)
  if not Teleporter.is_js_file(context, filename) then
    return false
  end

  local basename = util.get_basename(filename)
  if basename:match(suffix_in_context(context) .. "$") then
    return true
  end

  return false
end

---Return other context file path of given file
---@param context "test" | "story"
---@param filepath string
---@param workspace_path string
---@return string | nil
Teleporter.to_other_context = function(context, filepath, workspace_path)
  local conf = get_config()

  local path = Path:new(filepath)
  local sep = Path.path.sep

  local parent = path:parent()
  local ext = util.get_extension(path.filename)

  local filename = Teleporter.shave_path_from_start(path, parent)
  local basename = util.get_basename(filename)

  local context_basename = basename .. suffix_in_context(context) .. ext

  -- Check if it is on same directory
  local context_path = parent:joinpath(context_basename)
  if context_path:exists() then
    return context_path.filename
  end

  local context_root = Teleporter.find_other_context_root(context, parent, Path:new(workspace_path))
  if not context_root then
    return
  end

  local shaved = Teleporter.shave_path_from_start(path, context_root[1])
  local key_path = vim.fn.fnamemodify(string.gsub(shaved, "^" .. conf.source_root .. sep, ""), ":h")

  local context_key_path = parent:joinpath(context_root[2], key_path)
  local context_include_root_path = parent:joinpath(context_root[2], conf.source_root, key_path)

  -- foo/bar/src/foobar.ts → foo/bar/__${other_context}__/foobar.otherworld.ts
  context_path = context_key_path:joinpath(context_basename)
  if context_path:exists() then
    return context_path.filename
  end

  -- foo/bar/src/foobar.ts → foo/bar/__otherworld__/foobar.ts
  context_path = context_key_path:joinpath(basename)
  if context_path:exists() then
    return context_path.filename
  end

  -- foo/bar/src/foobar.ts → foo/bar/__otherworld__/src/foobar.otherworld.ts
  context_path = context_include_root_path:joinpath(context_basename)
  if context_path:exists() then
    return context_path.filename
  end

  -- foo/bar/src/foobar.ts → foo/bar/__otherworld__/src/foobar.ts
  context_path = context_include_root_path:joinpath(basename)
  if context_path:exists() then
    return context_path.filename
  end

  return nil
end

---@param context "test" | "story"
---@param filepath string
---@param workspace_path string
---@return string | nil
Teleporter.from_other_context = function(context, filepath, workspace_path)
  local conf = get_config()
  local sep = util.get_os_sep()

  local filename = util.get_basename(filepath)
  local dir = vim.fn.fnamemodify(filepath, ":h")
  local ext = util.get_extension(filepath)
  local suffix_removed = filename:gsub(suffix_in_context(context) .. "$", "") .. ext

  local target = ""
  if Teleporter.is_in_context(context, filepath) then
    local context_root = Teleporter.find_other_context_root(context, dir)

    if not context_root then
      vim.api.nvim_err_writeln("[JSTeleporter] Cannot determin context root directory.")
      return nil
    end

    local shaved = Teleporter.shave_path_from_start(filepath, context_root[0])
    local key_path = vim.fn.fnamemodify(string.gsub(shaved, "^" .. conf.source_root .. sep, ""), ":h")
    local src_root_path = conf.source_root .. sep .. key_path

    -- foo/bar/__otherworld__/foobar.otherworld.ts → foo/bar/src/foobar.ts
    target = context_root[0] .. sep .. src_root_path .. sep .. suffix_removed
    if util.exists(target) then
      return target
    end

    -- foo/bar/__otherworld__/foobar.otherworld.ts → foo/bar/foobar.ts
    target = context_root[0] .. sep .. key_path .. sep .. suffix_removed
    if util.exists(target) then
      return target
    end
  end

  -- explorer same folder
  target = dir .. sep .. suffix_removed
  if util.exists(target) then
    return target
  end

  return nil
end

Teleporter._get_suggestion_in_other_context = function(context, filepath, workspace_path)
  local conf = get_config()
  local sep = util.get_os_sep()

  local context_root = Teleporter.find_other_context_root(context, filepath, workspace_path)
  if not context_root then
    return
  end

  local shaved_path = Teleporter.shave_path_from_start(filepath, context_root[0])
  local key_path = vim.fn.fnamemodify(string.gsub(shaved_path, "^" .. conf.source_root .. sep .. "?", ""), ":h")

  local other_context_key_path = context_root[0] .. sep .. context_root[1]
  local other_context_root_path = context_root[0] .. sep .. conf.source_root

  local test_file_name = util.get_basename(filepath) .. suffix_in_context(context) .. util.get_extension(filepath)

  if util.exists(other_context_root_path) then
    return other_context_key_path .. sep .. key_path .. sep .. test_file_name
  else
    return other_context_key_path .. sep .. key_path .. test_file_name
  end
end

Teleporter._get_suggestion_in_same_dir = function(context, filepath, workspace_path)
  local path = Path:new(filepath)
  local other_context_filename = path.filename .. "." .. suffix_in_context(context) .. util.get_extension(filepath)

  return Path:joinpath(path:parent(), other_context_filename).filename
end

---@param context "test" | "story
---@param filepath string
---@param workspace_path string
---@return table {absolute_path, relative_path}[]
Teleporter.suggest_other_context_paths = function(context, filepath, workspace_path)
  local context_paths = {}
  -- return { "__tests__/lib/index.test.ts" }
  if not util.is_js_file(filepath) then
    return context_paths
  end

  if Teleporter.is_other_context_file(context, filepath) then
    return context_paths
  else
    -- HELPME!!
    local suggestion = Teleporter._get_suggestion_in_other_context(context, filepath, workspace_path)
    if not suggestion then
      suggestion = Teleporter._get_suggestion_in_same_dir(context, filepath, workspace_path)
    end

    local relative_path = Teleporter.shave_path_from_start(suggestion, workspace_path)
    return { suggestion, relative_path }
  end
end

---@param context "test" | "story"
---@param current_dir Path
---@param limit_dir Path?
---@return {[1]: Path, [2]: string} | nil
Teleporter.find_other_context_root = function(context, current_dir, limit_dir)
  local root = current_dir.path.root()

  while true do
    local other_context_root = find_other_context_root_dir_name(context, current_dir)
    if other_context_root then
      return { current_dir, other_context_root }
    end

    -- If the directory that specified in `test_source_roots` or `storybook_source_roots` does not exist,
    -- one of the following will occur. If it should not be cought as an error, please suppress this error message.
    if limit_dir ~= nil and current_dir.filename == limit_dir.filename then
      return nil
    end

    if util.is_same_dir(current_dir.filename, root) then
      return nil
    end

    current_dir = current_dir:parent()
  end
end

---@return string
Teleporter.shave_path_from_start = function(target, shaver_path)
  local target_elements = util.split(target.filename, target.path.sep)
  local shaver_elements = util.split(shaver_path.filename, shaver_path.path.sep)

  local match_index = 0
  for i, v in ipairs(target_elements) do
    local amount = shaver_elements[i]
    if v ~= amount then
      match_index = i
      break
    end
  end

  return table.concat(target_elements, util.get_os_sep(), match_index)
end

return Teleporter
