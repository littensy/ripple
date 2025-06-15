--[[
	Each benchmark runs a one-second tween animation that updates a property
	a specified number of times, measuring the performance of stepping through
	the animation.
]]

local bench = require("./bench")

local ITERATIONS = 10000

do
	local createTween = require("../packages/ripple/src/createTween")
	local heartbeat = require("../packages/ripple/src/createTween/heartbeat")

	bench("ripple", function()
		createTween(0, { start = true }):setGoal(1)

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
		createSingleMotor(0):setGoal(ease(1))

		for _ = 1, ITERATIONS do
			AnimationStepSignal:Fire(1 / ITERATIONS)
		end

		AnimationStepSignal:Clear()
	end)
end
