--[[
	Each benchmark runs a one-second tween animation that updates a property
	a specified number of times, measuring the performance of stepping through
	the animation.
]]

local bench = require("./bench")

local ITERATIONS = 10000

do
	local createTween = require("../packages/ripple/src/animation/createTween")
	local heartbeat = require("../packages/ripple/src/heartbeat")

	local config: createTween.TweenConfig = { start = true }

	bench("ripple", function()
		local tween = createTween(0, config)
		tween.to(1)

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

		for _ = 1, ITERATIONS do
			AnimationStepSignal:Fire(1 / ITERATIONS)
		end

		AnimationStepSignal:Clear()
	end)
end
