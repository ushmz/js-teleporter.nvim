local M = {}

M.config = {
  -- Root directory of source.
  source_root = "",
  -- Root directories of tests.
  -- Files under configured directories are considered tests.
  test_source_roots = {},
  -- Suffix to determine if the file is a test.
  test_file_suffix = "",
  -- Root directories of storybook.
  -- Files under configured directories are considered storybook.
  storybook_source_roots = {},
  -- Suffix to determine if the file is a storybook.
  storybook_file_suffix = "",

  extensions_for_test = { "ts", "js", "tsx", "jsx", "mts", "mjs", "cts", "cjs" },

  extensions_for_storybook = { "tsx", "jsx" },

  ignore_path = { "node_modules" },
}

---@param opts table: Configuration options
M.setup = function(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

M.hello = function()
  print("js-teleporter.nvim")
end

return M
