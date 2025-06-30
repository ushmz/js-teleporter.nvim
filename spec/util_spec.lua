local util = require("js-teleporter.util")
local logger = require("js-teleporter.logger")

local spy = require("luassert.spy")

describe("#get_path_difference", function()
  local original_cwd

  before_each(function()
    original_cwd = vim.fn.getcwd()
  end)

  after_each(function()
    vim.cmd("cd " .. original_cwd)
  end)

  it("should return different parts of path", function()
    vim.cmd("cd spec")
    assert.is_same(util.get_path_difference("fixtures/index.ts", "fixtures"), "index.ts")
  end)

  it("should return empty if the base_path is same as full_path", function()
    vim.cmd("cd spec")
    spy(logger.print_err):called(0)
    assert.is_same(util.get_path_difference("fixtures/index.ts", "fixtures/index.ts"), "")
  end)

  it("should return same path if base path is not a parent directory", function()
    vim.cmd("cd spec")
    assert.is_same(
      util.get_path_difference("fixtures/same_dir/src/index.ts", "fixtures/nearest_parent_dir/src"),
      "fixtures/same_dir/src/index.ts"
    )
  end)

  it("should return empty and print error message when base path is not a directory", function()
    vim.cmd("cd spec")
    spy(logger.print_err):called_with("Base path should be a directory: stories")
    assert.is_same(util.get_path_difference("src/path/to/index.ts", "stories"), "")
  end)

  it("should return the full_path when base_path is empty and full_path is not", function()
    vim.cmd("cd spec")
    spy(logger.print_err):called(0)
    assert.is_same(util.get_path_difference("fixtures/index.ts", ""), "fixtures/index.ts")
  end)

  it("should return an empty string when both full_path and base_path are empty", function()
    vim.cmd("cd spec")
    assert.is_same(util.get_path_difference("", ""), "")
  end)
end)
