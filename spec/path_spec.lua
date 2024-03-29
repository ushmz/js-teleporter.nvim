describe("path", function()
  local path = require("js-teleporter.path")
  describe("#split", function()
    it("can split words with given splitter", function()
      assert.is_same(path.split("a/b/c", "/"), { "a", "b", "c" })
    end)
  end)

  describe("#filename", function()
    it("can get filename from path", function()
      assert.is_equal(path.filename("path/to/file.lua"), "file.lua")
    end)
  end)

  describe("#basename", function()
    it("can get basename from path", function()
      assert.is_equal(path.basename("path/to/file.lua"), "file")
    end)
  end)

  describe("#extension", function()
    it("can get extension from path", function()
      assert.is_equal(path.extension("path/to/file.lua"), ".lua")
    end)
  end)

  describe("#match_any", function()
    it("can match any directory name", function()
      assert.is_true(path.match_any("path/to/file.lua", { "path" }))
      assert.is_true(path.match_any("path/to/file.lua", { "path", "dir" }))
      assert.is_false(path.match_any("path/to/file.lua", { "dir" }))
    end)
  end)

  describe("#find_any", function()
    -- TODO: implement
    it("can find any directory name", function() end)
  end)

  describe("#trim_unmatched_child_path", function()
    it("can trim unmatched child path", function()
      assert.is_equal(path.extract_unmatched_child_path("path/to/file.lua", "path/to/file1.lua"), "file.lua")
      assert.is_equal(path.extract_unmatched_child_path("path/to/file.lua", "path/file1.lua"), "to/file.lua")
      assert.is_equal(path.extract_unmatched_child_path("path/to/file.lua", "other/path/file1.lua"), "path/to/file.lua")
    end)
  end)
end)
