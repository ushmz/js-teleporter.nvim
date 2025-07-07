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
      vim.cmd("cd spec/fixtures")
      local context = {
        suffix = ".test",
        markers = { "__tests__" },
        root = "src",
      }

      assert.is_same(root_dir_strategy.from(context, "__tests__/lib/root_dir.test.ts"), "src/lib/root_dir.ts")
    end)

    it("> should transform a `.stories.tsx` path to its original `.tsx` source file", function()
      vim.cmd("cd spec/fixtures")
      local context = {
        suffix = ".stories",
        markers = { "__stories__" },
        root = "src",
      }

      assert.is_same(
        root_dir_strategy.from(context, "__stories__/components/root_dir.stories.tsx"),
        "src/components/root_dir.tsx"
      )
    end)

    it("> should return nil if suffix is not found in filename", function()
      vim.cmd("cd spec/fixtures")
      local context = {
        suffix = ".another",
        markers = { "__tests__" },
        root = "src",
      }
      assert.is_nil(root_dir_strategy.from(context, "__tests__/lib/root_dir.ts"))
    end)

    it("> should return nil if marker directory is not found in path", function()
      vim.cmd("cd spec/fixtures")
      local context = {
        suffix = ".test",
        markers = { "__nonexistent_marker__" },
        root = "src",
      }
      local result = root_dir_strategy.from(context, "__tests__/lib/root_dir.test.ts")
      assert.is_nil(result)
    end)

    it("> should return nil if target source file does not exist", function()
      vim.cmd("cd spec/fixtures")
      local context = {
        suffix = ".test",
        markers = { "__tests__" },
        root = "src_nonexistent",
      }
      local result = root_dir_strategy.from(context, "__tests__/lib/root_dir.test.ts")
      assert.is_nil(result)
    end)

    it("> should transform path when context.suffix is an empty string", function()
      vim.cmd("cd spec/fixtures")
      local context = {
        suffix = "",
        markers = { "__tests__" },
        root = "src",
      }

      assert.is_same(root_dir_strategy.from(context, "__tests__/lib/root_dir.ts"), "src/lib/root_dir.ts")
    end)

    it("> should transform path when context.suffix is nil", function()
      vim.cmd("cd spec/fixtures")
      local context = {
        suffix = nil,
        markers = { "__tests__" },
        root = "src",
      }

      assert.is_same(root_dir_strategy.from(context, "__tests__/lib/root_dir.ts"), "src/lib/root_dir.ts")
    end)
  end)

  describe("> to", function()
    it("> should transform a `.ts` path to its corresponding `.test.ts` path", function()
      vim.cmd("cd spec/fixtures")
      local context = {
        suffix = ".test",
        markers = { "__tests__" },
        root = "src",
      }

      assert.is_same(root_dir_strategy.to(context, "src/lib/root_dir.ts"), "__tests__/lib/root_dir.test.ts")
    end)

    it("> should transform a `.tsx` path to its corresponding `.stories.tsx` path", function()
      vim.cmd("cd spec/fixtures")
      local context = {
        suffix = ".stories",
        markers = { "__stories__" },
        root = "src",
      }

      assert.is_same(
        root_dir_strategy.to(context, "src/components/root_dir.tsx"),
        "__stories__/components/root_dir.stories.tsx"
      )
    end)

    it("should return nil if no target marker directory exists", function()
      vim.cmd("cd spec/fixtures")
      local context = {
        suffix = ".test",
        markers = { "__non_existent_tests__" },
        root = "src",
      }
      local result = root_dir_strategy.to(context, "src/lib/root_dir.ts")
      assert.is_nil(result)
    end)
  end)
end)
