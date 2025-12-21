local Ripple = require("../../Ripple")
local Vide = require("../../Vide")
local test = require("../../../../tests/test")
local useMotion = require("../useMotion")

test("should update binding when goal is set", function()
	local src, motion

	Vide.root(function()
		src, motion = useMotion(0)
		motion:setGoal(1, { tween = { duration = 0 } })
	end)

	Ripple.motionScheduler.step(1)
	assert(src() == 1, `Expected motion to reach goal, got {src()}`)
end)

return {}
