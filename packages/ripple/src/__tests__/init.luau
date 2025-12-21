local test = require("../../../tests/test")

test.describe("spring", function()
	require("@self/spring.test")
end)

test.describe("tween", function()
	require("@self/tween.test")
end)

test.describe("motion", function()
	require("@self/motion.test")
end)

test.describe("easing", function()
	require("@self/easing.test")
end)

test.describe("utils", function()
	test.describe("interpolate", function()
		require("@self/utils/interpolate.test")
	end)

	test.describe("oklab", function()
		require("@self/utils/oklab.test")
	end)
end)

return {}
