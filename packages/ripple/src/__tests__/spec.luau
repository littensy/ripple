local suite = require("../../../../test/suite")

suite.describe("createSpring", function()
	require("./createSpring.spec")
end)

suite.describe("createTween", function()
	require("./createTween.spec")
end)

suite.describe("createMotion", function()
	require("./createMotion.spec")
end)

suite.describe("utils", function()
	suite.describe("oklab", function()
		require("./utils/oklab.spec")
	end)
end)

suite.describe("easing", function()
	require("./easing.spec")
end)

suite.describe("spr", function()
	require("./spr.spec")
end)

return {}
