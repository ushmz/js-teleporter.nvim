local util = require("js-teleporter.util")

describe("#get_path_difference", function()
  local original_cwd

  before_each(function()
    original_cwd = vim.fn.getcwd()
  end)

  after_each(function()
    vim.cmd("cd " .. original_cwd)
  end)

  it("should return", function()
    vim.cmd("cd spec/tests")
    assert.is_same(util.get_path_difference("src/path/to/index.ts", "src/path"), "to/index.ts")
  end)

  it("should return same path if base path is not a parent directory", function()
    vim.cmd("cd spec/tests")
    assert.is_same(util.get_path_difference("src/path/to/index.ts", "src/path/to"), "index.ts")
  end)

  it("should return empty and print error message whtn base path is not a directory", function()
    assert.is_same(util.get_path_difference("src/path/to/index.ts", "stories"), "")
  end)
end)
