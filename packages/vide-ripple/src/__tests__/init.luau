local test = require("../../../tests/test")

test.describe("useSpring", function()
	require("@self/useSpring.test")
end)

test.describe("useTween", function()
	require("@self/useTween.test")
end)

test.describe("useMotion", function()
	require("@self/useMotion.test")
end)

return {}
