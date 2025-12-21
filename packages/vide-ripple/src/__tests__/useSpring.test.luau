local Ripple = require("../../Ripple")
local Vide = require("../../Vide")
local test = require("../../../../tests/test")
local useSpring = require("../useSpring")

test("should update binding when goal is set", function()
	local src, spring

	Vide.root(function()
		src, spring = useSpring(0)
		spring:setGoal(1, { tween = { duration = 0 } })
	end)

	Ripple.springScheduler.step(1)
	assert(src() == 1, `Expected spring to reach goal, got {src()}`)
end)

return {}
