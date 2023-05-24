describe("teleporter", function()
  local teleporter = require("js-teleporter")
  it("Work with default", function()
    assert("Say hello", teleporter.hello())
  end)

  it("Work with custom options", function()
    teleporter.setup({ source_root = "src" })
    assert("Options", teleporter.hello())
  end)
end)
