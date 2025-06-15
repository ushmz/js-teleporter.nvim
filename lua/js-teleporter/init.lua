local M = {}

local pathlib = require("js-teleporter.path")

---@param opts table: Configuration options
M.setup = function(opts)
  require("js-teleporter.config").set_options(opts)
end

---Suggest user to create new file if the destination file is not found
---@param context string
---@param suggestions Suggestion[]
M.suggest_to_create_file = function(context, suggestions)
  local select_items = {}

  for _, suggestion in ipairs(suggestions) do
    table.insert(select_items, suggestion.relative)
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
      vim.api.nvim_echo({ { "\n[JSTeleporter] File is not created.", "Normal" } }, true, {})
      return
    end

    local filepath = pathlib.create_file(choice)
    if filepath then
      vim.cmd.edit(filepath)
      vim.api.nvim_echo({ { '\n[JSTeleporter] "' .. choice .. '" created!', "Normal" } }, true, {})
    end
  end)
end

---Run teleport
---@param context "test" | "story"
---@param opts table
M.teleport = function(context, opts)
  local teleporter = require("js-teleporter.teleporter")

  local bufname = pathlib.get_filename_on_current_buffer()
  if not bufname then
    return
  end

  if not teleporter.is_js_file(context, bufname) then
    vim.api.nvim_err_writeln("[JSTeleporter] The file is not javascript/typescript.")
    return
  end

  local workspace_path = vim.api.nvim_call_function("getcwd", {})

  local destination = teleporter.teleport(context, bufname)
  if not destination or destination == "" then
    if teleporter.is_other_file(context, bufname) then
      vim.api.nvim_err_writeln("[JSTeleporter] Teleport destination is not found.")
      return
    end

    local suggestions = teleporter.suggest_other_file(context, bufname, workspace_path)
    if #suggestions == 0 then
      vim.api.nvim_err_writeln("[JSTeleporter] Teleport destination is not found.")
      return
    end

    M.suggest_to_create_file(context, suggestions)
    return
  end

  vim.cmd.edit(destination)
end

return M
