local pathlib = require("js-teleporter.path")

Teleporter = {}

function Teleporter.get_config()
  return require("js-teleporter.config").values
end

---Get roots in the context
---@param context "test" | "story"
---@return table
function Teleporter.roots_in_context(context)
  local conf = Teleporter.get_config()
  local roots = {}
  if context == "test" then
    roots = conf.test_roots
  elseif context == "story" then
    roots = conf.story_roots
  end

  return roots
end

---Get extensions in the context
---@param context "test" | "story"
---@return table
function Teleporter.extensions_in_context(context)
  local conf = Teleporter.get_config()

  local extensions = {}
  if context == "test" then
    extensions = conf.test_extensions
  elseif context == "story" then
    extensions = conf.story_extensions
  end

  return extensions
end

---Get suffix in the context
---@param context "test" | "story"
---@return string
function Teleporter.suffix_in_context(context)
  local conf = Teleporter.get_config()

  local suffix = ""
  if context == "test" then
    suffix = conf.test_file_suffix
  elseif context == "story" then
    suffix = conf.story_file_suffix
  end

  return suffix
end

---Return true if the file under the context is opened in current buffer
---@param context "test" | "story"
---@param filepath string
---@return boolean
function Teleporter.is_in_context(context, filepath)
  return pathlib.match_any(filepath, Teleporter.roots_in_context(context))
end

---@param context "test" | "story"
---@param current_dir string
---@param limit_dir string?
---@return { base_dir: string, dir_name: string } | nil
function Teleporter.find_context_root(context, current_dir, limit_dir)
  local root = pathlib.root
  local context_roots = Teleporter.roots_in_context(context)

  while true do
    local other_context_root = pathlib.find_any(current_dir, context_roots)
    if other_context_root then
      return { base_dir = current_dir, dir_name = other_context_root }
    end

    -- If the directory that specified in `test_source_roots` or `storybook_source_roots` does not exist,
    -- one of the following will occur. If it should not be cought as an error, please suppress this error message.
    if limit_dir ~= nil and current_dir == limit_dir then
      return nil
    end

    if pathlib.is_same_dir(current_dir, root) then
      return nil
    end

    current_dir = pathlib.parent_dir(current_dir)
  end
end

---Suggest the other side file path. It's not sure to exist.
---@param context "test" | "story"
---@param filename string
---@param workspace_dir string
---@return string
function Teleporter.suggest_other_file_in_same_dir(context, filename, workspace_dir)
  local parent = pathlib.parent_dir(filename)
  local other_context_filename = pathlib.basename(filename)
    .. Teleporter.suffix_in_context(context)
    .. pathlib.extension(filename)

  return pathlib.join_path(parent, other_context_filename)
end

---Suggests a possible path for the corresponding file in the opposite context.
---The existence of the suggested path is not guaranteed.
---@param context "test" | "story" -- The context of the suggested file (either "test" or "story").
---@param filename string -- The original filename for which the suggestion is made.
---@param workspace_dir string -- The root directory of the workspace.
---@return string | nil -- The suggested file path or nil if the suggestion couldn't be determined.
function Teleporter.suggest_other_file_in_context_root(context, filename, workspace_dir)
  local conf = Teleporter.get_config()

  local context_root = Teleporter.find_context_root(context, filename, workspace_dir)
  if not context_root then
    return nil
  end

  local shaved_path = pathlib.extract_unmatched_child_path(filename, context_root.base_dir)
  local key_path = vim.fn.fnamemodify(string.gsub(shaved_path, "^" .. conf.source_root .. pathlib.sep .. "?", ""), ":h")

  local context_key_path = pathlib.join_path(context_root.base_dir, context_root.dir_name)
  local source_root_included = pathlib.join_path(context_root.base_dir, context_root.dir_name, conf.source_root)

  local context_filename = pathlib.basename(filename)
    .. Teleporter.suffix_in_context(context)
    .. pathlib.extension(filename)

  if pathlib.exists(source_root_included) then
    return pathlib.join_path(source_root_included, key_path, context_filename)
  else
    return pathlib.join_path(context_key_path, key_path, context_filename)
  end
end

---Return existing other context file path of given file
---@param context "test" | "story"
---@param destination string
---@param workspace_path string
---@return string | nil
function Teleporter.teleport_to_other_file(context, destination, workspace_path)
  local conf = Teleporter.get_config()

  local parent = pathlib.parent_dir(destination)
  local ext = pathlib.extension(destination)

  local filename = pathlib.extract_unmatched_child_path(destination, parent)
  local basename = pathlib.basename(filename)

  local context_basename = basename .. Teleporter.suffix_in_context(context) .. ext

  -- Check if the other context file is in the same directory
  local context_path = pathlib.join_path(parent, context_basename)
  if pathlib.exists(context_path) then
    return context_path
  end

  local context_root = Teleporter.find_context_root(context, parent, workspace_path)
  if not context_root then
    return
  end

  local shaved = pathlib.extract_unmatched_child_path(destination, context_root.base_dir)
  local symmetry_path = vim.fn.fnamemodify(string.gsub(shaved, "^" .. conf.source_root .. pathlib.sep, ""), ":h")

  local key_path = pathlib.join_path(context_root.base_dir, context_root.dir_name, symmetry_path)
  local key_path_with_root =
    pathlib.join_path(context_root.base_dir, context_root.dir_name, conf.source_root, symmetry_path)

  -- foo/bar/src/foobar.ts -> foo/bar/${other_context}/foobar.suffix.ts
  context_path = pathlib.join_path(key_path, context_basename)
  if pathlib.exists(context_path) then
    return context_path
  end

  -- foo/bar/src/foobar.ts -> foo/bar/${other_context}/foobar.ts
  context_path = pathlib.join_path(key_path, basename)
  if pathlib.exists(context_path) then
    return context_path
  end

  -- foo/bar/src/foobar.ts -> foo/bar/${other_context}/src/foobar.suffix.ts
  context_path = pathlib.join_path(key_path_with_root, context_basename)
  if pathlib.exists(context_path) then
    return context_path
  end

  -- foo/bar/src/foobar.ts -> foo/bar/${other_context}/src/foobar.ts
  context_path = pathlib.join_path(key_path_with_root, basename)
  if pathlib.exists(context_path) then
    return context_path
  end

  return nil
end

---Return existing other side file
---@param context "test" | "story"
---@param destination string
---@param workspace_path string
---@return string | nil
function Teleporter.teleport_from_other_file(context, destination, workspace_path)
  local conf = Teleporter.get_config()

  local parent = pathlib.parent_dir(destination)
  local ext = pathlib.extension(destination)

  local filename = pathlib.extract_unmatched_child_path(destination, parent)
  local basename = pathlib.basename(filename)

  local suffix_removed = string.gsub(basename, Teleporter.suffix_in_context(context) .. "$", "") .. ext

  if Teleporter.is_in_context(context, destination) then
    local context_root = Teleporter.find_context_root(context, parent)
    if not context_root then
      return nil
    end

    local shaved = pathlib.extract_unmatched_child_path(destination, context_root.base_dir)
    local symmetry_path = vim.fn.fnamemodify(string.gsub(shaved, "^" .. context_root.dir_name .. pathlib.sep, ""), ":h")
    local symmetry_path_with_root = conf.source_root .. pathlib.sep .. symmetry_path

    -- foo/bar/${context_root}/foobar.suffix.ts -> foo/bar/src/foobar.ts
    local target = pathlib.join_path(context_root.base_dir, symmetry_path_with_root, suffix_removed)
    if pathlib.exists(target) then
      return target
    end

    -- foo/bar/${context_root}/foobar.suffix.ts -> foo/bar/foobar.ts
    target = pathlib.join_path(context_root.base_dir, symmetry_path, suffix_removed)
    if pathlib.exists(target) then
      return target
    end
  end

  -- explorer same folder
  local target = pathlib.join_path(parent, suffix_removed)
  if pathlib.exists(target) then
    return target
  end

  return nil
end

---Teleport to other file
---@param context "test" | "story"
---@param filename string
---@param workspace_path string
---@return string | nil
function Teleporter.teleport(context, filename, workspace_path)
  if not Teleporter.is_js_file(context, filename) then
    vim.api.nvim_err_writeln("[JSTeleporter] The file is not javascript/typescript. file: " .. filename)
    return
  end

  if Teleporter.is_other_file(context, filename) then
    return Teleporter.teleport_from_other_file(context, filename, workspace_path)
  else
    return Teleporter.teleport_to_other_file(context, filename, workspace_path)
  end
end

---Return if true the given file is a JS file
---@param context "test" | "story"
---@param filename string
---@return boolean
function Teleporter.is_js_file(context, filename)
  local ext = pathlib.extension(filename)
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
Teleporter.is_other_file = function(context, filename)
  if not Teleporter.is_js_file(context, filename) then
    return false
  end

  local basename = pathlib.basename(filename)
  if basename:match(Teleporter.suffix_in_context(context) .. "$") then
    return true
  end

  return false
end

---Suggest the other side file path. It's not sure to exist.
---@param context "test" | "story
---@param filename string
---@param workspace_dir string
---@return table {absolute_path, relative_path}
function Teleporter.suggest_other_file(context, filename, workspace_dir)
  if not Teleporter.is_js_file(context, filename) then
    return {}
  end

  if Teleporter.is_other_file(context, filename) then
    return {}
  end

  local suggestion = Teleporter.suggest_other_file_in_context_root(context, filename, workspace_dir)
  if not suggestion then
    suggestion = Teleporter.suggest_other_file_in_same_dir(context, filename, workspace_dir)
  end

  if suggestion == "" then
    return {}
  end

  local relative_path = pathlib.extract_unmatched_child_path(suggestion, workspace_dir)
  return { suggestion, relative_path }
end

return Teleporter
