local React = require("../../React")
local Ripple = require("../../Ripple")
local helpers = require("./helpers")
local test = require("../../../../tests/test")
local useMotion = require("../useMotion")

local render = helpers.render
local cleanup = helpers.cleanup

test.afterEach(function()
	cleanup()
end)

test("should update binding when goal is set in layout effect", function()
	local binding, motion

	local function LayoutMotion()
		binding, motion = useMotion(0)

		React.useLayoutEffect(function()
			motion:setGoal(1, { tween = { duration = 0 } })
		end, {})
	end

	render(React.createElement(LayoutMotion))

	Ripple.motionScheduler.step(1)
	assert(binding:getValue() == 1, `Expected motion to reach goal, got {binding:getValue()}`)
end)

return {}
