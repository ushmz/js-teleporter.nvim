local same_dir_strategy = require("js-teleporter.strategies.same_dir")

describe("same_dir", function()
  local original_cwd

  before_each(function()
    original_cwd = vim.fn.getcwd()
  end)

  after_each(function()
    vim.cmd("cd " .. original_cwd)
  end)

  describe("from", function()
    it("Return original file path", function()
      vim.cmd("cd spec/fixtures/same_dir")
      local context = {
        suffix = ".test",
        markers = { "__tests__" },
      }

      assert.is_same(same_dir_strategy.from(context, "src/index.test.ts"), "src/index.ts")
    end)
  end)

  describe("to", function()
    it("Return test file path", function()
      vim.cmd("cd spec/fixtures/same_dir")
      local context = {
        suffix = ".test",
        markers = { "__tests__" },
      }

      assert.is_same(same_dir_strategy.to(context, "src/index.ts"), "src/index.test.ts")
    end)

    it("Return story file path", function()
      vim.cmd("cd spec/fixtures/same_dir")
      local context = {
        suffix = ".stories",
        markers = { "__stories__" },
      }

      assert.is_same(same_dir_strategy.to(context, "src/index.tsx"), "src/index.stories.tsx")
    end)
  end)
end)
