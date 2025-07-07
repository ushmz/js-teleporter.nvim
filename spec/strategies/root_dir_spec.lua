local root_dir_strategy = require("js-teleporter.strategies.root_dir")

describe("RootDirectory Strategy", function()
  local original_cwd

  before_each(function()
    original_cwd = vim.fn.getcwd()
  end)

  after_each(function()
    vim.cmd("cd " .. original_cwd)
  end)

  describe("> from", function()
    it("> should transform a `.test.ts` path to its original `.ts` source file", function()
      vim.cmd("cd spec/fixtures/root_dir")
      local context = {
        suffix = ".test",
        markers = { "__tests__" },
        root = "src",
      }

      assert.is_same(root_dir_strategy.from(context, "__tests__/lib/index.test.ts"), "src/lib/index.ts")
    end)

    it("> should transform a `.stories.tsx` path to its original `.tsx` source file", function()
      vim.cmd("cd spec/fixtures/root_dir")
      local context = {
        suffix = ".stories",
        markers = { "__stories__" },
        root = "src",
      }

      assert.is_same(
        root_dir_strategy.from(context, "__stories__/components/index.stories.tsx"),
        "src/components/index.tsx"
      )
    end)

    it("> should return nil if suffix is not found in filename", function()
      vim.cmd("cd spec/fixtures/root_dir")
      local context = {
        suffix = ".another",
        markers = { "__tests__" },
        root = "src",
      }
      assert.is_nil(root_dir_strategy.from(context, "__tests__/lib/index.ts"))
    end)

    it("> should return nil if marker directory is not found in path", function()
      vim.cmd("cd spec/fixtures/root_dir")
      local context = {
        suffix = ".test",
        markers = { "__nonexistent_marker__" },
        root = "src",
      }
      local result = root_dir_strategy.from(context, "__tests__/lib/index.test.ts")
      assert.is_nil(result)
    end)

    it("> should return nil if target source file does not exist", function()
      vim.cmd("cd spec/fixtures/root_dir")
      local context = {
        suffix = ".test",
        markers = { "__tests__" },
        root = "src_nonexistent",
      }
      local result = root_dir_strategy.from(context, "__tests__/lib/index.test.ts")
      assert.is_nil(result)
    end)

    it("> should transform path when context.suffix is an empty string", function()
      vim.cmd("cd spec/fixtures/root_dir")
      local context = {
        suffix = "",
        markers = { "__tests__" },
        root = "src",
      }

      assert.is_same(root_dir_strategy.from(context, "__tests__/lib/index.ts"), "src/lib/index.ts")
    end)

    it("> should transform path when context.suffix is nil", function()
      vim.cmd("cd spec/fixtures/root_dir")
      local context = {
        suffix = nil,
        markers = { "__tests__" },
        root = "src",
      }

      assert.is_same(root_dir_strategy.from(context, "__tests__/lib/index.ts"), "src/lib/index.ts")
    end)
  end)

  describe("> to", function()
    it("> should transform a `.ts` path to its corresponding `.test.ts` path", function()
      vim.cmd("cd spec/fixtures/root_dir")
      local context = {
        suffix = ".test",
        markers = { "__tests__" },
        root = "src",
      }

      assert.is_same(root_dir_strategy.to(context, "src/lib/index.ts"), "__tests__/lib/index.test.ts")
    end)

    it("> should transform a `.tsx` path to its corresponding `.stories.tsx` path", function()
      vim.cmd("cd spec/fixtures/root_dir")
      local context = {
        suffix = ".stories",
        markers = { "__stories__" },
        root = "src",
      }

      assert.is_same(
        root_dir_strategy.to(context, "src/components/index.tsx"),
        "__stories__/components/index.stories.tsx"
      )
    end)

    it("should return nil if no target marker directory exists", function()
      vim.cmd("cd spec/fixtures/root_dir")
      local context = {
        suffix = ".test",
        markers = { "__non_existent_tests__" },
        root = "src",
      }
      local result = root_dir_strategy.to(context, "src/lib/index.ts")
      assert.is_nil(result)
    end)
  end)
end)
