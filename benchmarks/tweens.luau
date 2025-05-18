local bench = require("./bench")

local ITERATIONS = 10000

-- selene: allow(unused_variable)
local object = {
	property = 0,
}

do
	local createTween = require("../packages/ripple/src/animation/createTween")
	local heartbeat = require("../packages/ripple/src/heartbeat")

	local config: createTween.TweenConfig = { start = true }

	bench("ripple", function()
		local tween = createTween(0, config)

		tween.to(1)
		tween.onChange(function(value)
			object.property = value
		end)

		for _ = 1, ITERATIONS do
			heartbeat.step(1 / ITERATIONS)
		end

		heartbeat.clear()
	end)
end

do
	local AnimationStepSignal = require("./otter/AnimationStepSignal")
	local createSingleMotor = require("./otter/createSingleMotor")
	local ease = require("./otter/ease")

	bench("otter", function()
		local motor = createSingleMotor(0)

		motor:setGoal(ease(1))
		motor:onStep(function(value)
			object.property = value
		end)

		for _ = 1, ITERATIONS do
			AnimationStepSignal:Fire(1 / ITERATIONS)
		end

		AnimationStepSignal:Clear()
	end)
end
