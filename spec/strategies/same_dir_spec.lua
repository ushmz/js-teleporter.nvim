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
      vim.cmd("cd spec/fixtures")
      local context = {
        suffix = ".test",
        markers = { "__tests__" },
      }

      assert.is_same(same_dir_strategy.from(context, "src/lib/same_dir.test.ts"), "src/lib/same_dir.ts")
    end)
  end)

  describe("to", function()
    it("Return test file path", function()
      vim.cmd("cd spec/fixtures")
      local context = {
        suffix = ".test",
        markers = { "__tests__" },
      }

      assert.is_same(same_dir_strategy.to(context, "src/lib/same_dir.ts"), "src/lib/same_dir.test.ts")
    end)

    it("Return story file path", function()
      vim.cmd("cd spec/fixtures")
      local context = {
        suffix = ".stories",
        markers = { "__stories__" },
      }

      assert.is_same(same_dir_strategy.to(context, "src/components/same_dir.tsx"), "src/components/same_dir.stories.tsx")
    end)
  end)
end)
