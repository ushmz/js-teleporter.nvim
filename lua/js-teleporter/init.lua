local M = {}

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

  -- Show prompt and ask user to create the other context file or not
  vim.ui.select(select_items, {
    prompt = "The " .. context .. " file is not found. Create " .. context .. " file?",
  }, function(choice)
    if not choice then
      return
    end

    local filepath = require("js-teleporter.buffer").new_file(choice)
    if filepath then
      vim.cmd.edit(filepath)
      require("js-teleporter.logger").print_msg('"' .. choice .. '" created!')
    end
  end)
end

---Run teleport
---@param context "test" | "story"
---@param opts table
M.teleport = function(context, opts)
  local teleporter = require("js-teleporter.teleporter")

  local bufnr = vim.api.nvim_get_current_buf()
  local bufname = vim.api.nvim_buf_get_name(bufnr)
  if bufname == "" then
    return
  end

  if not require("js-teleporter.buffer").is_js_file(context, bufname) then
    require("js-teleporter.logger").print_err("The file is not javascript/typescript.")
    return
  end

  local workspace_path = vim.fn.getcwd()

  local destination = teleporter.teleport(context, bufname)
  if not destination or destination == "" then
    if require("js-teleporter.buffer").is_other_file(context, bufname) then
      require("js-teleporter.logger").print_err("Teleport destination is not found.")
      return
    end

    local suggestions = teleporter.suggest_other_file(context, bufname, workspace_path)
    if #suggestions == 0 then
      require("js-teleporter.logger").print_err("Teleport destination is not found.")
      return
    end

    M.suggest_to_create_file(context, suggestions)
    return
  end

  vim.cmd.edit(destination)
end

return M
