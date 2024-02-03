describe("Teleporter", function()
  -- Set default oprionts
  require("js-teleporter.config").set_options({})
  local teleporter = require("js-teleporter.teleporter")

  describe("#roots_in_context", function()
    it("can get root directories for test file", function()
      local test_roots = teleporter.roots_in_context("test")
      assert.is_same(test_roots, { "__tests__" })
    end)

    it("can get root directories for story file", function()
      local story_roots = teleporter.roots_in_context("story")
      assert.is_same(story_roots, { "stories" })
    end)
  end)

  describe("#extensions_in_context", function()
    it("can get extensions for test file", function()
      local test_exts = teleporter.extensions_in_context("test")
      assert.is_same(test_exts, { ".ts", ".js", ".tsx", ".jsx", ".mts", ".mjs", ".cts", ".cjs" })
    end)

    it("can get extensions for story file", function()
      local story_exts = teleporter.extensions_in_context("story")
      assert.is_same(story_exts, { ".tsx", ".jsx" })
    end)
  end)

  describe("#suffix_in_context", function()
    it("can get suffix of test file", function()
      local test_suffix = teleporter.suffix_in_context("test")
      assert.is_same(test_suffix, ".test")
    end)

    it("can get suffix of story file", function()
      local story_suffix = teleporter.suffix_in_context("story")
      assert.is_same(story_suffix, ".stories")
    end)
  end)

  describe("#is_in_context", function()
    it("can judge the given file path is in test context", function()
      assert.is_true(teleporter.is_in_context("test", "__tests__/path/to/file.test.js"))
    end)

    it("can judge the given file path is in storybook context", function()
      assert.is_true(teleporter.is_in_context("story", "stories/path/to/file.stories.tsx"))
    end)
  end)

  describe("#is_js_file", function()
    it("return true if the given file is JS file", function()
      local js_files = {
        { context = "test", file = "path/to/file.js" },
        { context = "test", file = "path/to/file.ts" },
        { context = "test", file = "path/to/file.jsx" },
        { context = "test", file = "path/to/file.tsx" },
        { context = "test", file = "path/to/file.test.js" },
        { context = "test", file = "path/to/file.test.ts" },
        { context = "test", file = "path/to/file.test.jsx" },
        { context = "test", file = "path/to/file.test.tsx" },
        { context = "story", file = "path/to/file.jsx" },
        { context = "story", file = "path/to/file.tsx" },
        { context = "story", file = "path/to/file.stories.jsx" },
        { context = "story", file = "path/to/file.stories.tsx" },
      }

      for _, t in ipairs(js_files) do
        assert.is_true(teleporter.is_js_file(t.context, t.file))
      end
    end)

    it("return false if the given file is not JS file", function()
      local other_files = {
        { context = "test", file = "path/to/file.json" },
        { context = "story", file = "path/to/file.json" },
      }

      for _, t in ipairs(other_files) do
        assert.is_false(teleporter.is_js_file(t.context, t.file))
      end
    end)
  end)

  describe("#is_other_file", function()
    it("can judge the given file is the other context file", function()
      local context_files = {
        { context = "test", file = "path/to/file.test.js" },
        { context = "test", file = "path/to/file.test.ts" },
        { context = "test", file = "path/to/file.test.jsx" },
        { context = "test", file = "path/to/file.test.tsx" },
        { context = "story", file = "path/to/file.stories.jsx" },
        { context = "story", file = "path/to/file.stories.tsx" },
      }

      for _, t in ipairs(context_files) do
        assert.is_true(teleporter.is_other_file(t.context, t.file))
      end

      local other_files = {
        { context = "test", file = "path/to/file.js" },
        { context = "story", file = "path/to/file.ts" },
        { context = "test", file = "path/to/file.json" },
        { context = "story", file = "path/to/file.json" },
      }

      for _, t in ipairs(other_files) do
        assert.is_false(teleporter.is_other_file(t.context, t.file))
      end
    end)
  end)

  describe("#suggest_other_file_in_same_dir", function()
    local workspace = vim.api.nvim_call_function("getcwd", {}) .. "/spec/tests"
    local target = workspace .. "/src/path/to/index.ts"

    it("can determine test file in same directory", function()
      local suggestions = teleporter.suggest_other_file_in_same_dir("test", target, workspace)

      assert.is_same(suggestions, workspace .. "/src/path/to/index.test.ts")
    end)

    it("can determine story file in same directory", function()
      local suggestions = teleporter.suggest_other_file_in_same_dir("story", target, workspace)

      assert.is_same(suggestions, workspace .. "/src/path/to/index.stories.ts")
    end)
  end)

  describe("#suggest_other_file_in_context_root", function()
    local workspace = vim.api.nvim_call_function("getcwd", {}) .. "/spec/tests"
    local target = workspace .. "/src/path/to/index.ts"

    it("can determine test file under the context root directory", function()
      local suggestions = teleporter.suggest_other_file_in_context_root("test", target, workspace)

      assert.is_same(suggestions, workspace .. "/__tests__/path/to/index.test.ts")
    end)

    it("can determine story file under the context root directory", function()
      local suggestions = teleporter.suggest_other_file_in_context_root("story", target, workspace)

      assert.is_same(suggestions, workspace .. "/stories/path/to/index.stories.ts")
    end)
  end)

  describe("#suggest_other_file", function()
    local workspace = vim.api.nvim_call_function("getcwd", {}) .. "/spec/tests"
    it("can suggest file paths under the other context", function()
      local suggestions = teleporter.suggest_other_file("test", workspace .. "/src/path/to/index.ts", workspace)

      assert.is_same(suggestions, {
        {
          absolute = workspace .. "/__tests__/path/to/index.test.ts",
          relative = "__tests__/path/to/index.test.ts",
        },
        {
          absolute = workspace .. "/src/path/to/index.test.ts",
          relative = "src/path/to/index.test.ts",
        },
      })
    end)
  end)

  describe("#teleport_to_other_file", function()
    local workspace = vim.api.nvim_call_function("getcwd", {}) .. "/spec/tests"

    it("can teleport to the test file", function()
      local base_file = workspace .. "/src/path/to/index.ts"
      local destination = teleporter.teleport_to_other_file("test", base_file, workspace)

      assert.is_same(destination, workspace .. "/__tests__/path/to/index.test.ts")
    end)

    it("can teleport to the story file", function()
      local base_file = workspace .. "/src/path/to/index.tsx"
      local destination = teleporter.teleport_to_other_file("story", base_file, workspace)

      assert.is_same(destination, workspace .. "/stories/path/to/index.stories.tsx")
    end)
  end)

  describe("#teleport_from_other_file", function()
    local workspace = vim.api.nvim_call_function("getcwd", {}) .. "/spec/tests"

    it("can teleport from the test file", function()
      local test_file = workspace .. "/__tests__/path/to/index.test.ts"
      local destination = teleporter.teleport_from_other_file("test", test_file, workspace)

      assert.is_same(destination, workspace .. "/src/path/to/index.ts")
    end)

    it("can teleport from the story file", function()
      local story_file = workspace .. "/stories/path/to/index.stories.tsx"
      local destination = teleporter.teleport_from_other_file("story", story_file, workspace)

      assert.is_same(destination, workspace .. "/src/path/to/index.tsx")
    end)
  end)

  describe("#teleport", function()
    local workspace = vim.api.nvim_call_function("getcwd", {}) .. "/spec/tests"

    it("can teleport from the base file to the test file", function()
      local base_file = workspace .. "/src/path/to/index.ts"
      local destination = teleporter.teleport("test", base_file, workspace)

      assert.is_same(destination, workspace .. "/__tests__/path/to/index.test.ts")
    end)

    it("can teleport from the base file to the story file", function()
      local base_file = workspace .. "/src/path/to/index.tsx"
      local destination = teleporter.teleport("story", base_file, workspace)

      assert.is_same(destination, workspace .. "/stories/path/to/index.stories.tsx")
    end)

    it("can teleport from the test file to the base file", function()
      local test_file = workspace .. "/__tests__/path/to/index.test.ts"
      local destination = teleporter.teleport("test", test_file, workspace)

      assert.is_same(destination, workspace .. "/src/path/to/index.ts")
    end)

    it("can teleport from the story file to the base file", function()
      local story_file = workspace .. "/stories/path/to/index.stories.tsx"
      local destination = teleporter.teleport("story", story_file, workspace)

      assert.is_same(destination, workspace .. "/src/path/to/index.tsx")
    end)
  end)
end)
