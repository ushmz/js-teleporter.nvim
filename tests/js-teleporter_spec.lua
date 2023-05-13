local teleporter = require("js-teleporter")

describe("teleporter", function()
  it("Work with default", function()
    assert("Say hello", teleporter.hello())
  end)
end)
