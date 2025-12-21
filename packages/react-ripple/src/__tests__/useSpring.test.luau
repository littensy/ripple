local React = require("../../React")
local Ripple = require("../../Ripple")
local helpers = require("./helpers")
local test = require("../../../../tests/test")
local useSpring = require("../useSpring")

local render = helpers.render
local cleanup = helpers.cleanup

test.afterEach(function()
	cleanup()
end)

test("should update binding when goal is set in layout effect", function()
	local binding, spring

	local function LayoutSpring()
		binding, spring = useSpring(0)

		React.useLayoutEffect(function()
			spring:setGoal(1)
		end, {})
	end

	render(React.createElement(LayoutSpring))

	Ripple.springScheduler.step(1)
	assert(binding:getValue() == 1, `Expected spring to reach goal, got {binding:getValue()}`)
end)

return {}
