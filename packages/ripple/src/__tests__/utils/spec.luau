local suite = require("../../../../../test/suite")

suite.describe("easing", function()
	require("./easing.spec")
end)

suite.describe("oklab", function()
	require("./oklab.spec")
end)

return {}
