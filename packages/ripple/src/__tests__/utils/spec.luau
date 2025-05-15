local suite = require("../../../../../test/suite")

suite.describe("fuzzyEqual", function()
	require("./fuzzyEqual.spec")
end)

suite.describe("oklab", function()
	require("./oklab.spec")
end)

return {}
