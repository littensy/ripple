--[[
	Each benchmark runs a prolonged spring animation that updates a property
	a specified number of times, measuring the performance of stepping through
	the animation.
]]

local bench = require("./bench")

local ITERATIONS = 10000

do
	local createSpring = require("../packages/ripple/src/animation/createSpring")
	local heartbeat = require("../packages/ripple/src/heartbeat")

	bench("ripple", function()
		createSpring(0, { start = true, frequency = 1 / 10 }):setGoal(1)

		for _ = 1, ITERATIONS do
			heartbeat.step(1 / ITERATIONS)
		end

		heartbeat.clear()
	end)
end

do
	local spr = require("./spr/spr")

	bench("spr", function()
		spr.target({ value = 0 }, 1, 1 / 10, { value = 1 })

		for _ = 1, ITERATIONS do
			spr.step(1 / ITERATIONS)
		end

		spr.clear()
	end)
end

do
	local AnimationStepSignal = require("./otter/AnimationStepSignal")
	local createSingleMotor = require("./otter/createSingleMotor")
	local spring = require("./otter/spring")

	bench("otter", function()
		createSingleMotor(0):setGoal(spring(1, { frequency = 1 / 10 }))

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

do
	local SpringValue = require("./react-flow/SpringValue")

	bench("react-flow", function()
		local spring = SpringValue.new(0, 1 / 10)

		spring:SetGoal(1)
		spring:Run()

		for _ = 1, ITERATIONS do
			SpringValue.step(1 / ITERATIONS)
		end

		SpringValue.clear()
	end)
end
