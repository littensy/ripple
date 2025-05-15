local suite = require("./suite")

suite.describe("ripple", function()
	require("../packages/ripple/src/__tests__/spec")
end)

suite.finish({ verbose = false })
