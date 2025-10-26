local bench = require("./bench")

local SPRINGS = 100
local ITERATIONS = 1000

do
	local spring = require("../packages/ripple/src/spring")
	local createSpring = spring.createSpring
	local scheduler = spring.scheduler

	bench("ripple", function()
		for _ = 1, SPRINGS do
			createSpring(0, { start = true, frequency = 1 / 10 }):setGoal(1)
		end

		for _ = 1, ITERATIONS do
			scheduler.step(1 / ITERATIONS)
		end

		scheduler.clear()
	end)
end

do
	local AnimationStepSignal = require("./otter/AnimationStepSignal")
	local createSingleMotor = require("./otter/createSingleMotor")
	local spring = require("./otter/spring")

	bench("otter", function()
		for _ = 1, SPRINGS do
			createSingleMotor(0):setGoal(spring(1, { frequency = 1 / 10 }))
		end

		for _ = 1, ITERATIONS do
			AnimationStepSignal:Fire(1 / ITERATIONS)
		end

		AnimationStepSignal:Clear()
	end)
end

do
	local spring, step, clear = require("./vide/spring")()
	local root = require("./vide/root")

	local function goal()
		return 1
	end

	bench("vide", function()
		root(function(cleanup)
			for _ = 1, SPRINGS do
				spring(goal, 10)(0)
			end

			for _ = 1, ITERATIONS do
				-- This function has been modified to run at a variable
				-- frequency instead of the 120 Hz fixed frequency
				step(1 / ITERATIONS)
			end

			clear()
			cleanup()
		end)
	end)
end
