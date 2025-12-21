local React = require("../../React")
local Ripple = require("../../Ripple")
local helpers = require("./helpers")
local test = require("../../../../tests/test")
local useTween = require("../useTween")

local render = helpers.render
local cleanup = helpers.cleanup

test.afterEach(function()
	cleanup()
end)

test("should update binding when goal is set in layout effect", function()
	local binding, tween

	local function LayoutTween()
		binding, tween = useTween(0)

		React.useLayoutEffect(function()
			tween:setGoal(1, { duration = 0 })
		end, {})
	end

	render(React.createElement(LayoutTween))

	Ripple.tweenScheduler.step(1)
	assert(binding:getValue() == 1, `Expected tween to reach goal, got {binding:getValue()}`)
end)

return {}
