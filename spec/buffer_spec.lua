local buffer = require("js-teleporter.buffer")
local logger = require("js-teleporter.logger")

local stub = require("luassert.stub")
local spy = require("luassert.spy")

local opts = {
  -- Root directory of source.
  source_root = "src",
  -- Root directories of tests.
  -- Files under configured directories are considered tests.
  test_roots = { "__tests__" },
  -- Suffix to determine if the file is a test.
  test_file_suffix = ".test",
  -- Root directories of storybook.
  -- Files under configured directories are considered storybook.
  story_roots = { "stories" },
  -- Suffix to determine if the file is a storybook.
  story_file_suffix = ".stories",
  -- Extensions to determine if the file is a test file.
  test_extensions = { ".ts", ".js", ".tsx", ".jsx", ".mts", ".mjs", ".cts", ".cjs" },
  -- Extensions to determine if the file is a storybook.
  story_extensions = { ".tsx", ".jsx" },
  -- Files in these directories are ignored
  ignore_path = { "node_modules" },
}

describe("#is_js_file", function()
  describe("> context = test", function()
    it("> return true if given file is Javascript related file", function()
      assert.is_true(buffer.is_js_file("test", "index.js", opts))
      assert.is_true(buffer.is_js_file("test", "index.ts", opts))
      assert.is_true(buffer.is_js_file("test", "index.test.ts", opts))
      assert.is_true(buffer.is_js_file("test", "index.test.ts", opts))
    end)

    it("> return false if given file is not Javascript related file", function()
      assert.is_false(buffer.is_js_file("test", "init.lua", opts))
    end)
  end)

  describe("> context = story", function()
    it("> return true if given file is Javascript related file", function()
      assert.is_true(buffer.is_js_file("story", "index.jsx", opts))
      assert.is_true(buffer.is_js_file("story", "index.tsx", opts))
      assert.is_true(buffer.is_js_file("story", "index.stories.jsx", opts))
      assert.is_true(buffer.is_js_file("story", "index.stories.tsx", opts))
    end)

    it("> return false if given file is not Javascript related file", function()
      assert.is_false(buffer.is_js_file("story", "init.lua", opts))
    end)
  end)
end)

describe("#is_other_file", function()
  describe("> context = test", function()
    it("> return true if given file is test related file", function()
      assert.is_true(buffer.is_other_file("test", "index.test.ts", opts))
      assert.is_true(buffer.is_other_file("test", "index.test.ts", opts))
    end)

    it("> return false if given file is not test related file", function()
      assert.is_false(buffer.is_other_file("test", "index.js", opts))
      assert.is_false(buffer.is_other_file("test", "index.ts", opts))
    end)
  end)

  describe("> context = story", function()
    it("> return true if given file is storybook related file", function()
      assert.is_true(buffer.is_other_file("story", "index.stories.jsx", opts))
      assert.is_true(buffer.is_other_file("story", "index.stories.tsx", opts))
    end)

    it("> return false if given file is not storybook related file", function()
      assert.is_false(buffer.is_other_file("story", "index.jsx", opts))
      assert.is_false(buffer.is_other_file("story", "index.tsx", opts))
    end)
  end)
end)

describe("#new_file", function()
  it("> return empty and print error message if given filepath is nil", function()
    local logger_stub = stub(logger, "print_err")

    ---@diagnostic disable-next-line: param-type-mismatch
    assert.is_same(buffer.new_file(nil), nil)
    ---@diagnostic disable-next-line: undefined-field
    assert.stub(logger_stub).called(1)
  end)

  it("> doesn't call `vim.fn.writefile` if the given file is already exist", function()
    stub(vim.fn, "filereadable", 1)
    local writefile_spy = spy.on(vim.fn, "writefile")

    buffer.new_file("index.ts")
    ---@diagnostic disable-next-line: undefined-field
    assert.spy(writefile_spy).was_not_called()
  end)

  it("> call `vim.fn.writefile` if the given file is not exist", function()
    stub(vim.fn, "filereadable", 0)
    local writefile_stub = stub(vim.fn, "writefile")

    buffer.new_file("index.ts")
    ---@diagnostic disable-next-line: undefined-field
    assert.stub(writefile_stub).called(1)
  end)
end)
