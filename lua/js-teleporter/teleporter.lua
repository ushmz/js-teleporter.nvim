local Path = require("plenary.path")

Teleporter = {}

Teleporter.get_config = function()
  return require("js-teleporter.config").values
end

---Get roots in the context
---@param context "test" | "story"
---@return table
Teleporter.roots_in_context = function(context)
  local conf = Teleporter.get_config()
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
Teleporter.extensions_in_context = function(context)
  local conf = Teleporter.get_config()

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
Teleporter.suffix_in_context = function(context)
  local conf = Teleporter.get_config()

  local suffix = ""
  if context == "test" then
    suffix = conf.test_file_suffix
  elseif context == "story" then
    suffix = conf.storybook_file_suffix
  end

  return suffix
end

Teleporter.get_os_sep = function()
  return require("plenary.path").path.sep
end

---Return filename of given file
---@param filepath string
---@return string
Teleporter.get_filename = function(filepath)
  local parts = {}
  for part in filepath:gmatch("[^%" .. Teleporter.get_os_sep() .. "]+") do
    table.insert(parts, part)
  end
  return table.remove(parts)
end

---Return basename of given file
---@param filepath string
---@return string
Teleporter.get_basename = function(filepath)
  local file = Teleporter.get_filename(filepath)

  local parts = {}
  for part in file:gmatch("[^%.]+") do
    table.insert(parts, part)
  end
  table.remove(parts)
  return table.concat(parts, ".")
end

---Return extensions of given file
---@param file string
---@return string
Teleporter.get_extension = function(file)
  local ext = file:match("^.+(%..+)$")
  return ext
end

---@param dir1 string
---@param dir2 string
---@return boolean
Teleporter.is_same_dir = function(dir1, dir2)
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
Teleporter.scan_dir = function(dir)
  return require("plenary.scandir").scan_dir(dir, { only_dirs = true, depth = 1 })
end

---@param filepath string
---@return boolean
Teleporter.exists = function(filepath)
  -- [TODO] This puts error message, suppress message and go through
  -- require("plenary.path").exists(filepath)
  local f = io.open(filepath, "r")
  if f == nil then
    return false
  end
  io.close(f)
  return true
end

---@param target string
---@param splitter string
---@return string[]
Teleporter.split = function(target, splitter)
  local parts = {}
  for part in string.gmatch(target, "([^" .. splitter .. "]+)") do
    table.insert(parts, part)
  end
  return parts
end

---Return true if the other context file is opened in current buffer
---@param context "test" | "story"
---@param filepath string
---@return boolean
Teleporter.is_in_context = function(context, filepath)
  local sep = Teleporter.get_os_sep()

  for _, v in ipairs(Teleporter.roots_in_context(context)) do
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

---@param target Path
---@param shaver_path Path
---@return string
Teleporter.shave_path_from_start = function(target, shaver_path)
  if target.filename == "" then
    return ""
  end

  if shaver_path.filename == "" then
    return target.filename
  end

  local sep = Teleporter.get_os_sep()
  local target_elements = Teleporter.split(target.filename, sep)
  local shaver_elements = Teleporter.split(shaver_path.filename, sep)

  local match_index = 0
  for i, v in ipairs(target_elements) do
    local amount = shaver_elements[i]
    if v ~= amount then
      match_index = i
      break
    end
  end

  return table.concat(target_elements, sep, match_index)
end

---@param context "test" | "story"
---@param current_dir Path
---@return string | nil
Teleporter.find_other_context_root_dir_name = function(context, current_dir)
  if not current_dir:is_dir() then
    return
  end

  -- NOTE : `scan_dir()` returns only directories
  local dirs = Teleporter.scan_dir(current_dir.filename)
  for _, file in ipairs(dirs) do
    for _, v in ipairs(Teleporter.roots_in_context(context)) do
      if current_dir .. Teleporter.get_os_sep() .. v == file then
        return v
      end
    end
  end
end

---@param context "test" | "story"
---@param current_dir Path
---@param limit_dir Path?
---@return {base_dir: Path, context_root: string} | nil
Teleporter.find_other_context_root = function(context, current_dir, limit_dir)
  local root = Path.path.root()

  while true do
    local other_context_root = Teleporter.find_other_context_root_dir_name(context, current_dir)
    if other_context_root then
      return { base_dir = current_dir, context_root = other_context_root }
    end

    -- If the directory that specified in `test_source_roots` or `storybook_source_roots` does not exist,
    -- one of the following will occur. If it should not be cought as an error, please suppress this error message.
    if limit_dir ~= nil and current_dir.filename == limit_dir.filename then
      return nil
    end

    if Teleporter.is_same_dir(current_dir.filename, root) then
      return nil
    end

    current_dir = current_dir:parent()
  end
end

---@param context "test" | "story"
---@param filepath Path
---@param workspace_path Path
---@return Path
Teleporter.get_suggestion_in_same_dir = function(context, filepath, workspace_path)
  local other_context_filename = Teleporter.get_filename(filepath.filename)
    .. "."
    .. Teleporter.suffix_in_context(context)
    .. Teleporter.get_extension(filepath.filename)

  return Path:joinpath(filepath:parent(), other_context_filename)
end

---comment
---@param context "test" | "story"
---@param filepath Path
---@param workspace_path Path
---@return Path | nil
Teleporter.get_suggestion_in_other_context = function(context, filepath, workspace_path)
  local conf = Teleporter.get_config()
  local sep = Teleporter.get_os_sep()

  local context_root = Teleporter.find_other_context_root(context, filepath, workspace_path)
  if not context_root then
    return nil
  end

  local shaved_path = Teleporter.shave_path_from_start(filepath, context_root.base_dir)
  local key_path = vim.fn.fnamemodify(string.gsub(shaved_path, "^" .. conf.source_root .. sep .. "?", ""), ":h")

  local context_key_path = context_root.base_dir:joinpath(context_root.context_root)
  local source_root_included = context_root.base_dir:joinpath(context_root.context_root, conf.source_root)

  local context_filename = Teleporter.get_basename(filepath.filename)
    .. Teleporter.suffix_in_context(context)
    .. Teleporter.get_extension(filepath.filename)

  if source_root_included:exists() then
    return source_root_included:joinpath(key_path, context_filename)
  else
    return context_key_path:joinpath(key_path, context_filename)
  end
end

---Return other context file path of given file
---@param context "test" | "story"
---@param destination string
---@param workspace_path string
---@return string | nil
Teleporter.to_other_context = function(context, destination, workspace_path)
  local conf = Teleporter.get_config()

  local path = Path:new(destination)
  local sep = Path.path.sep

  local parent = path:parent()
  local ext = Teleporter.get_extension(path.filename)

  local filename = Teleporter.shave_path_from_start(path, parent)
  local basename = Teleporter.get_basename(filename)

  local context_basename = basename .. Teleporter.suffix_in_context(context) .. ext

  -- Check if the other context file is in the same directory
  local context_path = parent:joinpath(context_basename)
  if context_path:exists() then
    return context_path.filename
  end

  local context_root = Teleporter.find_other_context_root(context, parent, Path:new(workspace_path))
  if not context_root then
    return
  end

  local shaved = Teleporter.shave_path_from_start(path, context_root.base_dir)
  local key_path = vim.fn.fnamemodify(string.gsub(shaved, "^" .. conf.source_root .. sep, ""), ":h")

  local context_key_path = parent:joinpath(context_root.context_root, key_path)
  local context_include_root_path = parent:joinpath(context_root.context_root, conf.source_root, key_path)

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
---@param destination string
---@param workspace_path string
---@return string | nil
Teleporter.from_other_context = function(context, destination, workspace_path)
  local conf = Teleporter.get_config()

  local path = Path:new(destination)
  local sep = path.sep

  local parent = path:parent()
  local ext = Teleporter.get_extension(destination)

  local filename = Teleporter.shave_path_from_start(path, parent)
  local basename = Teleporter.get_basename(filename)

  local suffix_removed = string.gsub(basename, Teleporter.suffix_in_context(context) .. "$", "") .. ext

  if Teleporter.is_in_context(context, destination) then
    local context_root = Teleporter.find_other_context_root(context, parent)
    if not context_root then
      -- vim.api.nvim_err_writeln("[JSTeleporter] Cannot determin context root directory.")
      return nil
    end

    local shaved = Teleporter.shave_path_from_start(path, context_root.base_dir)
    local key_path = vim.fn.fnamemodify(string.gsub(shaved, "^" .. conf.source_root .. sep, ""), ":h")
    local src_root_path = conf.source_root .. sep .. key_path

    -- foo/bar/__otherworld__/foobar.otherworld.ts → foo/bar/src/foobar.ts
    local target = context_root.base_dir:joinpath(src_root_path, suffix_removed)
    if Teleporter.exists(target.filename) then
      return target.filename
    end

    -- foo/bar/__otherworld__/foobar.otherworld.ts → foo/bar/foobar.ts
    target = context_root.base_dir:joinpath(key_path, suffix_removed)
    if Teleporter.exists(target.filename) then
      return target.filename
    end
  end

  -- explorer same folder
  local target = parent:joinpath(suffix_removed)
  if Teleporter.exists(target.filename) then
    return target.filename
  end

  return nil
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

---Return if true the given file is a JS file
---@param context "test" | "story"
---@param filename string
---@return boolean
Teleporter.is_js_file = function(context, filename)
  local filepath = Path:new(filename)
  local ext = Teleporter.get_extension(filepath.filename)
  for _, v in ipairs(Teleporter.extensions_in_context(context)) do
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

  local basename = Teleporter.get_basename(filename)
  if basename:match(Teleporter.suffix_in_context(context) .. "$") then
    return true
  end

  return false
end

---@param context "test" | "story
---@param filename string
---@param workspace_dir string
---@return table {absolute_path, relative_path}[]
Teleporter.suggest_other_context_paths = function(context, filename, workspace_dir)
  if not Teleporter.is_js_file(context, filename) then
    return {}
  end

  if Teleporter.is_other_context_file(context, filename) then
    return {}
  end

  local filepath = Path:new(filename)
  local workspace_path = Path:new(workspace_dir)
  local suggestion = Teleporter.get_suggestion_in_other_context(context, filepath, workspace_path)
  if not suggestion then
    suggestion = Teleporter.get_suggestion_in_same_dir(context, filepath, workspace_path)
  end

  if suggestion.filename == "" then
    return {}
  end

  local relative_path = Teleporter.shave_path_from_start(suggestion, workspace_path)
  return { suggestion, relative_path }
end

local function build_instance_method(instance, bytecode_of_method)
  return load(bytecode_of_method, nil, "b", instance)
end

Teleporter.new = function(context)
  local instance = {}

  instance.sep = Teleporter.get_os_sep()
  instance.roots = Teleporter.roots_in_context(context)
  instance.extensions = Teleporter.extensions_in_context(context)
  instance.suffix = Teleporter.suffix_in_context(context)

  setmetatable(instance, { __index = _ENV })

  instance.suggest_other_context_paths =
    build_instance_method(instance, string.dump(Teleporter.suggest_other_context_paths))
  instance.is_js_file = build_instance_method(instance, string.dump(Teleporter.is_js_file))
  instance.is_other_context_file = build_instance_method(instance, string.dump(Teleporter.is_other_context_file))
  instance.teleport_to = build_instance_method(instance, string.dump(Teleporter.teleport_to))

  return instance
end

return Teleporter
