local Ripple = require("../../Ripple")
local Vide = require("../../Vide")
local test = require("../../../../tests/test")
local useTween = require("../useTween")

test("should update binding when goal is set", function()
	local src, tween

	Vide.root(function()
		src, tween = useTween(0)
		tween:setGoal(1, { tween = { duration = 0 } })
	end)

	Ripple.tweenScheduler.step(1)
	assert(src() == 1, `Expected tween to reach goal, got {src()}`)
end)

return {}
