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

	bench("ripple group", function()
		createSpring({ 0, 0, 0 }, { start = true, frequency = 1 / 10 }):setGoal({ 1, 1, 1 })

		for _ = 1, ITERATIONS do
			heartbeat.step(1 / ITERATIONS)
		end

		heartbeat.clear()
	end)
end

do
	local createSpring = require("../packages/ripple/src/animation/createSpring")
	local heartbeat = require("../packages/ripple/src/heartbeat")

	bench("ripple single", function()
		for _ = 1, 3 do
			createSpring(0, { start = true, frequency = 1 / 10 }):setGoal(1)
		end

		for _ = 1, ITERATIONS do
			heartbeat.step(1 / ITERATIONS)
		end

		heartbeat.clear()
	end)
end

do
	local spr = require("./spr/spr")

	bench("spr", function()
		spr.target({ x = 0, y = 0, z = 0 }, 1, 1 / 10, { x = 1, y = 1, z = 1 })

		for _ = 1, ITERATIONS do
			spr.step(1 / ITERATIONS)
		end

		spr.clear()
	end)
end

do
	local AnimationStepSignal = require("./otter/AnimationStepSignal")
	local createGroupMotor = require("./otter/createGroupMotor")
	local spring = require("./otter/spring")

	bench("otter group", function()
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

do
	local AnimationStepSignal = require("./otter/AnimationStepSignal")
	local createSingleMotor = require("./otter/createSingleMotor")
	local spring = require("./otter/spring")

	bench("otter single", function()
		for _ = 1, 3 do
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
			for _ = 1, 3 do
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
