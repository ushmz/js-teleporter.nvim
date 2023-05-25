local teleporter = require("js-teleporter").setup({})

local eq = assert.are.same

describe("# Utilities functions: ", function()
  local teleporter = require("js-teleporter/teleporter")
  it("Can judge js file", function()
    eq(teleporter.is_js_file("test", "index.ts"), true)
    eq(teleporter.is_js_file("test", "index.test.ts"), true)
    eq(teleporter.is_js_file("test", "index.jsx.ts"), true)
    eq(teleporter.is_js_file("test", "index.tsx.ts"), true)
  end)

  it("Can judge other context file", function()
    eq(teleporter.is_other_context_file("test", "index.test.ts"), true)
    eq(teleporter.is_other_context_file("test", "index.tests.ts"), false)
    eq(teleporter.is_other_context_file("story", "index.story.tsx"), false)
    eq(teleporter.is_other_context_file("story", "index.stories.tsx"), true)
  end)

  it("Can get file name from abusolute path", function()
    eq(teleporter.get_filename("path/to/dir/index.ts"), "index.ts")
  end)

  it("Can get file extension from abusolute path", function()
    eq(teleporter.get_extension("path/to/dir/index.ts"), ".ts")
    eq(teleporter.get_extension("path/to/dir/index.test.ts"), ".ts")
  end)

  it("Can split string with splitter", function()
    eq(teleporter.split("path/to/index.ts", "/"), { "path", "to", "index.ts" })
  end)

  it("Can get if the given filepath is in the context", function()
    eq(teleporter.is_in_context("test", "path/to/index.ts"), false)
    eq(teleporter.is_in_context("test", "__tests__/path/to/index.ts"), true)
    eq(teleporter.is_in_context("story", "path/to/index.ts"), false)
    eq(teleporter.is_in_context("story", "stories/path/to/index.ts"), true)
  end)

  it("Can extract common parts of two file path", function()
    -- eq(teleporter.shave_path_from_start())
  end)

  it("Can suggest other context file path", function()
    eq(teleporter.suggest_other_context_paths("test", "index.ts", "workspace").suggestion, "index.test.ts")
  end)
end)
