local util = require("js-teleporter.util")

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
  -- TODO
  local suggestion_paths = teleporter.suggest_other_context_paths(context, filename, workspace_path)
  if #suggestion_paths == 0 then
    vim.api.nvim_echo({ { "[JSTeleporter] destination is not found", "Normal" } }, true, {})
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
    if choice == "No" then
      vim.api.nvim_echo({ { "\n[JSTeleporter] File is not created", "Normal" } }, true, {})
      return
    end
    util.create_file(choice)
    util.open_file(choice)
    vim.api.nvim_echo({ { '\n[JSTeleporter] "' .. choice .. '" created!', "Normal" } }, true, {})
  end)
end

---Run teleport
---@param context "test" | "story"
---@param opts table
M.teleport = function(context, opts)
  local teleporter = require("js-teleporter.teleporter")

  local bufname = util.get_filename_on_current_buffer()
  if not bufname then
    return
  end

  if not teleporter.is_js_file(context, bufname) then
    vim.api.nvim_err_writeln("[JSTeleporter] The file is not javascript/typescript. file: " .. bufname)
    return
  end

  -- TODO
  local workspace_path = vim.api.nvim_call_function("getcwd", {})

  local destination = teleporter.teleport_to(context, bufname, workspace_path)
  if not destination then
    if teleporter.is_other_context_file(context, bufname) then
      vim.api.nvim_err_writeln("[JSTeleporter] Teleport destination is not found.")
      return
    end
    M.suggest_to_create_test(context, teleporter, bufname, workspace_path)
    return
  end
  util.open_file(destination)
end

return M
