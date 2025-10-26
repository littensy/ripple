local bench = require("./bench")

local ITERATIONS = 10000

do
	local tween = require("../packages/ripple/src/tween")
	local createTween = tween.createTween
	local scheduler = tween.scheduler

	bench("ripple", function()
		createTween(0, { start = true }):setGoal(1)

		for _ = 1, ITERATIONS do
			scheduler.step(1 / ITERATIONS)
		end

		scheduler.clear()
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
