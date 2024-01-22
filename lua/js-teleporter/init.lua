local M = {}

local pathlib = require("js-teleporter.path")

---@param opts table: Configuration options
M.setup = function(opts)
  require("js-teleporter.config").set_options(opts)
end

---Suggest user to create new file if the destination file is not found
---@param context string
---@param teleporter any
---@param filename string
---@param workspace_path string
M.suggest_to_create_file = function(context, teleporter, filename, workspace_path)
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

    local filepath = pathlib.create_file(choice)
    if filepath then
      vim.cmd.edit(filepath)
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

  local bufname = pathlib.get_filename_on_current_buffer()
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
    M.suggest_to_create_file(context, Teleporter, bufname, workspace_path)
    return
  end

  vim.cmd.edit(destination)
end

return M
