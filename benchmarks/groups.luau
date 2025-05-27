--[[
	Each benchmark runs a number of prolonged spring animation that updates a
	property a specified number of times, measuring the performance of multiple
	spring animations running at the same time.
]]

local bench = require("./bench")

local ITERATIONS = 10000

do
	local createSpring = require("../packages/ripple/src/animation/createSpring")
	local heartbeat = require("../packages/ripple/src/heartbeat")

	local config: createSpring.SpringConfig = {
		start = true,
		frequency = 1 / 10,
	}

	bench("ripple", function()
		createSpring(0, config).to(1)
		createSpring(0, config).to(1)
		createSpring(0, config).to(1)

		for _ = 1, ITERATIONS do
			heartbeat.step(1 / ITERATIONS)
		end

		heartbeat.clear()
	end)
end

do
	local AnimationStepSignal = require("./otter/AnimationStepSignal")
	local createGroupMotor = require("./otter/createGroupMotor")
	local spring = require("./otter/spring")

	local config: spring.SpringOptions = { frequency = 1 / 10 }

	bench("otter group", function()
		local motor = createGroupMotor({ 0, 0, 0 } :: { [any]: number })

		motor:setGoal({
			[1] = spring(1, config),
			[2] = spring(1, config),
			[3] = spring(1, config),
		} :: { [any]: any })

		for _ = 1, ITERATIONS do
			AnimationStepSignal:Fire(1 / ITERATIONS)
		end

		AnimationStepSignal:Clear()
	end)
end

do
	local AnimationStepSignal = require("./otter/AnimationStepSignal")
	local createSingleMotor = require("./otter/createSingleMotor")
	local spring = require("./otter/spring")

	local config: spring.SpringOptions = { frequency = 1 / 10 }

	bench("otter single", function()
		createSingleMotor(0):setGoal(spring(1, config))
		createSingleMotor(0):setGoal(spring(1, config))
		createSingleMotor(0):setGoal(spring(1, config))

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
			spring(goal, 10)(0)
			spring(goal, 10)(0)
			spring(goal, 10)(0)

			for _ = 1, ITERATIONS do
				-- This step function runs at a variable frequency instead of
				-- the 120hz fixed frequency normally used in Vide
				step(1 / ITERATIONS)
			end

			clear()
			cleanup()
		end)
	end)
end
