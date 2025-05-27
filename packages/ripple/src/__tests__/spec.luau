local heartbeat = require("../heartbeat")
local suite = require("../../../../test/suite")

suite.afterEach(function()
	heartbeat.clear()
end)

suite.describe("animation", function()
	require("./animation/spec")
end)

suite.describe("utils", function()
	require("./utils/spec")
end)

suite.describe("easing", function()
	require("./easing.spec")
end)

return {}
