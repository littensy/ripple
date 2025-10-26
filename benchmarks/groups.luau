local bench = require("./bench")

local ITERATIONS = 10000

do
	local spring = require("../packages/ripple/src/spring")
	local createSpring = spring.createSpring
	local scheduler = spring.scheduler

	bench("ripple", function()
		createSpring({ 0, 0, 0 }, { start = true, frequency = 1 / 10 }):setGoal({ 1, 1, 1 })

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
		local motor = createGroupMotor({ x = 0, y = 0, z = 0 })

		motor:setGoal({
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
