local suite = require("../../../../test/suite")

suite.describe("spring", function()
	require("./spring.spec")
end)

suite.describe("tween", function()
	require("./tween.spec")
end)

suite.describe("motion", function()
	require("./motion.spec")
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
