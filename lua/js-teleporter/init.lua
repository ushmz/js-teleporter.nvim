local Path = require("plenary.path")

---@param filepath string
---@return boolean
local exists = function(filepath)
  -- [TODO] This puts error message, suppress message and go through
  -- require("plenary.path").exists(filepath)
  local f = io.open(filepath, "r")
  if f == nil then
    return false
  end
  io.close(f)
  return true
end

---@return boolean
local is_dir = function(path)
  if Path.is_path(path) then
    return Path.is_dir(path)
  end
  return Path:new(path):is_dir()
end

---Open file with current buffer
---@param path string
local open_file = function(path)
  vim.cmd.edit(path)
end

---Create new file with given path
---@param filepath string
local create_file = function(filepath)
  if not filepath then
    return
  end

  if filepath == "" then
    vim.api.nvim_err_writeln("[JSTeleporter] Please enter a valid file or folder name")
    return
  end

  local path = Path:new(filepath)
  if exists(path.filename) then
    return path
  end

  if is_dir(path.filename) then
    Path:new(path.filename:sub(1, -2)):mkdir({ parents = true })
  else
    path:touch({ parents = true })
  end
  return path
end

---Get filename on current buffer. Return empty ("") if current buffer is empty.
---@return string | nil
local get_filename_on_current_buffer = function()
  local bufnr = vim.api.nvim_get_current_buf()
  if not bufnr then
    return
  end
  return vim.api.nvim_buf_get_name(bufnr)
end

local M = {}

---@param opts table: Configuration options
M.setup = function(opts)
  require("js-teleporter.config").set_options(opts)
end

---Suggest user to create new file if the destination file is not found
---@param context string
---@param teleporter any
---@param filename string
---@param workspace_path string
M.suggest_to_create_test = function(context, teleporter, filename, workspace_path)
  local suggestion_paths = teleporter.suggest_other_context_paths(context, filename, workspace_path)
  if #suggestion_paths == 0 then
    vim.api.nvim_err_writeln("[JSTeleporter] Teleport destination is not found.")
    return
  end

  local select_items = {}
  for _, v in ipairs(suggestion_paths) do
    table.insert(select_items, v)
  end
  table.insert(select_items, "No")

  -- Show prompt and ask user to create the other context file or not
  vim.ui.select(select_items, {
    prompt = "The " .. context .. " file is not found. Create " .. context .. " file?",
  }, function(choice)
    if not choice then
      return
    end

    if choice == "No" then
      vim.api.nvim_echo({ "[JSTeleporter] File is not created.", "Normal" }, true, {})
      return
    end

    local path = create_file(choice)
    if path then
      open_file(path.filename)
      vim.api.nvim_echo({ { '[JSTeleporter] "' .. choice .. '" created!', "Normal" } }, true, {})
    end
  end)
end

---Run teleport
---@param context "test" | "story"
---@param opts table
M.teleport = function(context, opts)
  local Teleporter = require("js-teleporter.teleporter")
  local teleporter = Teleporter.new(context)

  local bufname = get_filename_on_current_buffer()
  if not bufname then
    return
  end

  if not Teleporter.is_js_file(context, bufname) then
    vim.api.nvim_err_writeln("[JSTeleporter] The file is not javascript/typescript.")
    return
  end

  local workspace_path = vim.api.nvim_call_function("getcwd", {})

  local destination = Teleporter.teleport_to(context, bufname, workspace_path)
  if not destination then
    if Teleporter.is_other_context_file(context, bufname) then
      vim.api.nvim_err_writeln("[JSTeleporter] Teleport destination is not found.")
      return
    end
    M.suggest_to_create_test(context, Teleporter, bufname, workspace_path)
    return
  end
  open_file(destination)
end

return M
