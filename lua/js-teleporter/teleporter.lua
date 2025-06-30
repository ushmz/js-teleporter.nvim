local Teleporter = {}

---Get roots in the context
---@param context "test" | "story"
---@return table
function Teleporter.roots_in_context(context)
  if context ~= "test" and context ~= "story" then
    require("js-teleporter.logger").print_err("Invalid context: " .. context)
    return {}
  end

  if context == "test" then
    return require("js-teleporter.config").values.test_roots
  elseif context == "story" then
    return require("js-teleporter.config").values.story_roots
  end

  return {}
end

---Get suffix in the context
---@param context "test" | "story"
---@return string
function Teleporter.suffix_in_context(context)
  if context ~= "test" and context ~= "story" then
    require("js-teleporter.logger").print_err("Invalid context: " .. context)
    return ""
  end

  if context == "test" then
    return require("js-teleporter.config").values.test_file_suffix
  elseif context == "story" then
    return require("js-teleporter.config").values.story_file_suffix
  end

  return ""
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

-- FIXME: Perhaps `absolute` is not needed.
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

  ---@type  TeleportContext
  local ctx = {
    suffix = Teleporter.suffix_in_context(context),
    markers = Teleporter.roots_in_context(context),
  }

  local nearest_parent_dir = require("js-teleporter.strategies.nearest_parent_dir").to(ctx, filename)
  if nearest_parent_dir ~= "" then
    table.insert(suggestions, {
      absolute = nearest_parent_dir,
      relative = require("js-teleporter.util").get_path_difference(nearest_parent_dir, workspace_dir),
    })
  end

  local in_same_dir = require("js-teleporter.strategies.same_dir").to(ctx, filename)
  if in_same_dir ~= "" then
    table.insert(
      suggestions,
      {
        absolute = in_same_dir,
        relative = require("js-teleporter.util").get_path_difference(in_same_dir, workspace_dir),
      }
    )
  end

  return suggestions
end

return Teleporter
