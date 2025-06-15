local util = require("js-teleporter.util")

describe("#get_path_difference", function()
  it("should return", function()
    assert.is_same(util.get_path_difference("/project/root/src/main.js", "/project/root/"), "src/main.js")
  end)

  it("should return same path if base path is not a parent directory", function ()
    assert.is_same(util.get_path_difference("/another/dir/file.c", "/project/root/"), "/another/dir/file.c")
  end)

  it("should return empty and print error message whtn base path is not a directory", function ()
    assert.is_same(util.get_path_difference("/project/root/file.txt", "/project/root/file.txt"), "")
  end)
end)
