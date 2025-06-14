local heartbeat = require("../heartbeat")
local suite = require("../../../../test/suite")

suite.afterEach(function()
	heartbeat.clear()
end)

suite.describe("animation", function()
	suite.describe("createMotion", function()
		require("./animation/createMotion.spec")
	end)
	suite.describe("createSpring", function()
		require("./animation/createSpring.spec")
	end)
	suite.describe("createTween", function()
		require("./animation/createTween.spec")
	end)
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
