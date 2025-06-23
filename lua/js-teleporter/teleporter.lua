local pathlib = require("js-teleporter.path")

Teleporter = {}

---@return TeleporterConfig
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
---@param filename string
---@return string | nil
function Teleporter.teleport_to(context, filename)
  ---@type  TeleportContext
  local ctx = {
    suffix = Teleporter.suffix_in_context(context),
    markers = Teleporter.roots_in_context(context),
  }

  local same_dir_dest = require("js-teleporter.strategies.same_dir").to(ctx, filename)
  if same_dir_dest and vim.fn.filereadable(same_dir_dest) == 1 then
    return same_dir_dest
  end

  local parent_dir_dest = require("js-teleporter.strategies.nearest_parent_dir").to(ctx, filename)
  if parent_dir_dest and vim.fn.filereadable(parent_dir_dest) == 1 then
    return parent_dir_dest
  end

  return nil
end

---Return existing other side file
---@param context "test" | "story"
---@param filename string
---@return string | nil
function Teleporter.teleport_from(context, filename)
  ---@type  TeleportContext
  local ctx = {
    suffix = Teleporter.suffix_in_context(context),
    markers = Teleporter.roots_in_context(context),
  }

  local same_dir_dest = require("js-teleporter.strategies.same_dir").from(ctx, filename)
  if same_dir_dest and vim.fn.filereadable(same_dir_dest) == 1 then
    return same_dir_dest
  end

  local parent_dir_dest = require("js-teleporter.strategies.nearest_parent_dir").from(ctx, filename)
  if parent_dir_dest and vim.fn.filereadable(parent_dir_dest) == 1 then
    return parent_dir_dest
  end

  return nil
end

---Teleport to other file
---@param context "test" | "story"
---@param filename string
---@return string | nil
function Teleporter.teleport(context, filename)
  if not require("js-teleporter.buffer").is_js_file(context, filename) then
    require("js-teleporter.logger").print_err("The file is not javascript/typescript. file: " .. filename)
    return
  end

  if require("js-teleporter.buffer").is_other_file(context, filename) then
    return Teleporter.teleport_from(context, filename)
  else
    return Teleporter.teleport_to(context, filename)
  end
end

---@class Suggestion
---@field absolute string
---@field relative string

---Suggest the other side file path. It's not sure to exist.
---@param context "test" | "story
---@param filename string
---@param workspace_dir string
---@return Suggestion[]
function Teleporter.suggest_other_file(context, filename, workspace_dir)
  if not require("js-teleporter.buffer").is_js_file(context, filename) then
    return {}
  end

  if require("js-teleporter.buffer").is_other_file(context, filename) then
    return {}
  end

  local suggestions = {}
  local under_ctx_root = Teleporter.suggest_other_file_in_context_root(context, filename, workspace_dir)
  if under_ctx_root then
    table.insert(
      suggestions,
      { absolute = under_ctx_root, relative = pathlib.extract_unmatched_child_path(under_ctx_root, workspace_dir) }
    )
  end

  local in_same_dir = Teleporter.suggest_other_file_in_same_dir(context, filename, workspace_dir)
  if in_same_dir ~= "" then
    table.insert(
      suggestions,
      { absolute = in_same_dir, relative = pathlib.extract_unmatched_child_path(in_same_dir, workspace_dir) }
    )
  end

  return suggestions
end

return Teleporter
