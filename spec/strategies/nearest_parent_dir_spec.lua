local nearest_parent_dir_strategy = require("js-teleporter.strategies.nearest_parent_dir")

describe("nearest_parent_dir", function()
  local original_cwd

  before_each(function()
    original_cwd = vim.fn.getcwd()
  end)

  after_each(function()
    vim.cmd("cd " .. original_cwd)
  end)

  describe("from", function()
    it("Return original file path for test file", function()
      vim.cmd("cd spec/fixtures")
      local context = {
        suffix = ".test",
        markers = { "__tests__" },
      }

      assert.is_same(nearest_parent_dir_strategy.from(context, "src/lib/__tests__/nearest_parent_dir.test.ts"), "src/lib/nearest_parent_dir.ts")
    end)

    it("Return original file path for stories file", function()
      vim.cmd("cd spec/fixtures")
      local context = {
        suffix = ".stories",
        markers = { "__stories__" },
      }

      assert.is_same(nearest_parent_dir_strategy.from(context, "src/__stories__/nearest_parent_dir.stories.tsx"), "src/nearest_parent_dir.tsx")
    end)
  end)

  describe("to", function()
    it("Return test file path", function()
      vim.cmd("cd spec/fixtures")
      local context = { suffix = ".test", markers = { "__tests__" } }

      assert.is_same(
        nearest_parent_dir_strategy.to(context, vim.fs.joinpath(vim.fn.getcwd(), "src/lib/nearest_parent_dir.ts")),
        vim.fs.joinpath(vim.fn.getcwd(), "src/lib/__tests__/nearest_parent_dir.test.ts")
      )
    end)

    it("Return stories file path", function()
      vim.cmd("cd spec/fixtures")
      local context = { suffix = ".stories", markers = { "__stories__" } }
      assert.is_same(
        nearest_parent_dir_strategy.to(context, vim.fs.joinpath(vim.fn.getcwd(), "src/nearest_parent_dir.tsx")),
        vim.fs.joinpath(vim.fn.getcwd(), "src/__stories__/nearest_parent_dir.stories.tsx")
      )
    end)
  end)
end)
