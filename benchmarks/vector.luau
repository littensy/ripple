local bench = require("./bench")

local ITERATIONS = 10000

do
	local spring = require("../packages/ripple/src/spring")
	local createSpring = spring.createSpring
	local scheduler = spring.scheduler

	bench("ripple", function()
		createSpring(vector.zero, { start = true, frequency = 1 / 10 }):setGoal(vector.one)

		for _ = 1, ITERATIONS do
			scheduler.step(1 / ITERATIONS)
		end

		scheduler.clear()
	end)
end

do
	local AnimationStepSignal = require("./otter/AnimationStepSignal")
	local createGroupMotor = require("./otter/createGroupMotor")
	local spring = require("./otter/spring")

	bench("otter", function()
		createGroupMotor({ x = 0, y = 0, z = 0 }):setGoal({
			x = spring(1, { frequency = 1 / 10 }),
			y = spring(1, { frequency = 1 / 10 }),
			z = spring(1, { frequency = 1 / 10 }),
		})

		for _ = 1, ITERATIONS do
			AnimationStepSignal:Fire(1 / ITERATIONS)
		end

		AnimationStepSignal:Clear()
	end)
end

do
	local root = require("./vide/root")
	local spring, step, clear = require("./vide/spring")()

	local function goal()
		return vector.one
	end

	bench("vide", function()
		root(function(cleanup)
			spring(goal, 10)(vector.zero)

			for _ = 1, ITERATIONS do
				-- This function has been modified to run at a variable
				-- frequency instead of the 120 Hz fixed frequency
				step(1 / ITERATIONS)
			end

			cleanup()
			clear()
		end)
	end)
end
