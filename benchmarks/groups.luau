--[[
	Each benchmark runs a number of prolonged spring animation that updates a
	property a specified number of times, measuring the performance of multiple
	spring animations running at the same time.
]]

local bench = require("./bench")

local GROUPS = 3
local ITERATIONS = 10000

do
	local createSpring = require("../packages/ripple/src/animation/createSpring")
	local heartbeat = require("../packages/ripple/src/heartbeat")

	local config: createSpring.SpringConfig = {
		start = true,
		frequency = 1 / 10,
	}

	bench("ripple", function()
		for _ = 1, GROUPS do
			createSpring(0, config).to(1)
		end

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
	local initialState: { [any]: number } = table.create(GROUPS, 0)

	bench("otter group", function()
		local motor = createGroupMotor(initialState)
		local goals = table.create(GROUPS)

		for i = 1, GROUPS do
			goals[i] = spring(1, config)
		end

		motor:setGoal(goals :: { [any]: any })

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

	bench("otter singles", function()
		for _ = 1, GROUPS do
			createSingleMotor(0):setGoal(spring(1, config))
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
			for _ = 1, GROUPS do
				spring(goal, 10)(0)
			end

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
