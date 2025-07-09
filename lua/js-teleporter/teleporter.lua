local config = require("js-teleporter.config")

local Teleporter = {}

---Return existing other context file path of given file
---@param context "test" | "story"
---@param filename string
---@return string | nil
function Teleporter.teleport_to(context, filename)
  ---@type  TeleportContext
  local ctx = {
    suffix = config:context_suffix(context),
    markers = config:context_roots(context),
    root = config:src_root(),
  }

  local same_dir_dest = require("js-teleporter.strategies.same_dir").to(ctx, filename)
  if same_dir_dest and vim.fn.filereadable(same_dir_dest) == 1 then
    return same_dir_dest
  end

  local root_dir_dest = require("js-teleporter.strategies.root_dir").to(ctx, filename)
  if root_dir_dest and vim.fn.filereadable(root_dir_dest) == 1 then
    return root_dir_dest
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
    suffix = config:context_suffix(context),
    markers = config:context_roots(context),
    root = config:src_root(),
  }

  local same_dir_dest = require("js-teleporter.strategies.same_dir").from(ctx, filename)
  if same_dir_dest and vim.fn.filereadable(same_dir_dest) == 1 then
    return same_dir_dest
  end

  local root_dir_dest = require("js-teleporter.strategies.root_dir").from(ctx, filename)
  if root_dir_dest and vim.fn.filereadable(root_dir_dest) == 1 then
    return root_dir_dest
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
---@param opts TeleporterConfig
---@return string | nil
function Teleporter.teleport(context, filename, opts)
  if not require("js-teleporter.buffer").is_js_file(context, filename, opts) then
    require("js-teleporter.logger").print_err("The file is not javascript/typescript. file: " .. filename)
    return
  end

  if require("js-teleporter.buffer").is_other_file(context, filename, opts) then
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
---@param opts TeleporterConfig
---@return Suggestion[]
function Teleporter.suggest_other_file(context, filename, workspace_dir, opts)
  if not require("js-teleporter.buffer").is_js_file(context, filename, opts) then
    return {}
  end

  if require("js-teleporter.buffer").is_other_file(context, filename, opts) then
    return {}
  end

  local suggestions = {}

  ---@type  TeleportContext
  local ctx = {
    suffix = config:context_suffix(context),
    markers = config:context_roots(context),
    root = config:src_root(),
  }

  local nearest_parent_dir = require("js-teleporter.strategies.nearest_parent_dir").to(ctx, filename)
  if nearest_parent_dir then
    table.insert(suggestions, {
      absolute = nearest_parent_dir,
      relative = require("js-teleporter.util").get_path_difference(nearest_parent_dir, workspace_dir),
    })
  end

  local root_dir = require("js-teleporter.strategies.root_dir").to(ctx, filename)
  if root_dir then
    table.insert(suggestions, {
      absolute = root_dir,
      relative = require("js-teleporter.util").get_path_difference(root_dir, workspace_dir),
    })
  end

  local in_same_dir = require("js-teleporter.strategies.same_dir").to(ctx, filename)
  if in_same_dir then
    table.insert(suggestions, {
      absolute = in_same_dir,
      relative = require("js-teleporter.util").get_path_difference(in_same_dir, workspace_dir),
    })
  end

  return suggestions
end

return Teleporter
