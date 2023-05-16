local util = require("js-teleporter.util")

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

local find_other_context_root_dir_name = function(context, current_dir)
  if not util.is_dir(current_dir) then
    return
  end

  local files = util.scan_dir(current_dir)
  for _, file in ipairs(files) do
    for _, v in ipairs(roots_in_context(context)) do
      if v == file then
        if util.is_dir(current_dir .. util.get_os_sep() .. file) then
          return v
        end
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
    return Teleporter.from_other_context(filename, workspace_path)
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
  local sep = util.get_os_sep()

  local dir = vim.fn.fnamemodify(filepath, ":h")
  local ext = util.get_extension(filepath)
  local filename = Teleporter.shave_path_from_start(filepath, dir)
  local basename = util.get_basename(filename)

  local other_context_basename = basename .. suffix_in_context(context) .. ext
  if util.exists(dir .. sep .. other_context_basename) then
    return dir .. sep .. other_context_basename
  end

  -- (this.shavePathFromStart(filepath, baseRoot).replace(new RegExp(`^${this.root}${path.sep}?`), ''));
  local context_root = Teleporter.find_other_context_root(context, workspace_path)
  if not context_root then
    return
  end
  local key_path = vim.fn.fnamemodify(
    Teleporter.shave_path_from_start("", context_root[0]):gsub("^" .. conf.source_root .. sep, ""),
    ":h"
  )

  local other_context_key_path = dir .. sep .. roots_in_context(context) .. key_path
  local other_context_include_root_path = dir .. sep .. roots_in_context(context) .. conf.source_root .. key_path

  -- foo/bar/src/foobar.ts → foo/bar/__${other_context}__/foobar.otherworld.ts
  if util.exists(other_context_key_path .. sep .. other_context_basename) then
    return other_context_key_path .. sep .. other_context_basename
  end

  -- foo/bar/src/foobar.ts → foo/bar/__otherworld__/foobar.ts
  if util.exists(other_context_key_path .. sep .. basename) then
    return other_context_key_path .. sep .. basename
  end

  -- foo/bar/src/foobar.ts → foo/bar/__otherworld__/src/foobar.otherworld.ts
  if util.exists(other_context_include_root_path .. sep .. other_context_basename) then
    return other_context_include_root_path .. sep .. other_context_basename
  end

  -- foo/bar/src/foobar.ts → foo/bar/__otherworld__/src/foobar.ts
  if util.exists(other_context_include_root_path .. sep .. basename) then
    return other_context_include_root_path .. sep .. basename
  end

  return nil
end

Teleporter.from_other_context = function(context, filepath, workspace_path)
  local filename = util.get_basename(filepath)
  local ext = util.get_extension(filepath)
  local suffix_removed = filename:gsub(suffix_in_context(context) .. "$", "") .. ext

  if Teleporter.is_in_context(context, filepath) then
    local dir = Teleporter.find_other_context_root(filepath)
  end
end

Teleporter.suggest_other_context_paths = function(context, filename, workspace_path)
  return { "__tests__/lib/index.test.ts" }
end

Teleporter.find_other_context_root = function(context, current_dir, limit_dir)
  -- TODO
  local root = "/"

  while true do
    local other_context_root = find_other_context_root_dir_name(context, current_dir)
    if other_context_root then
      return { current_dir, other_context_root }
    end

    if limit_dir ~= nil and util.is_same_dir(current_dir, limit_dir) then
      vim.api.nvim_err_writeln("[JSTeleporter] Teleport destination is not found.")
      return nil
    end

    if util.is_same_dir(current_dir, root) then
      vim.api.nvim_err_writeln("[JSTeleporter] Teleport destination is not found.")
      return nil
    end

    current_dir = vim.fn.fnamemodify(current_dir, ":h")
  end
end

---@param target string
---@param shaver_path string
---@return string
Teleporter.shave_path_from_start = function(target, shaver_path)
  local target_elements = util.split(target, util.get_os_sep())
  local shaver_elements = util.split(shaver_path, util.get_os_sep())

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
