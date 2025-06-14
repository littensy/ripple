--[[
	Each benchmark runs a prolonged spring animation on a 3D vector, measuring
	the performance of stepping through the animation and converting the
	internal representation to and from vectors.

	For libraries that do not natively support vectors, the goal will be a
	table with x, y, and z properties.
]]

local bench = require("./bench")

local ITERATIONS = 10000

do
	local createSpring = require("../packages/ripple/src/animation/createSpring")
	local heartbeat = require("../packages/ripple/src/heartbeat")

	bench("ripple", function()
		createSpring(vector.zero, { start = true, frequency = 1 / 10 }):setGoal(vector.one)

		for _ = 1, ITERATIONS do
			heartbeat.step(1 / ITERATIONS)
		end

		heartbeat.clear()
	end)
end

do
	local spr = require("./spr/spr")

	bench("spr", function()
		spr.target({ value = vector.zero }, 1, 1 / 10, { value = vector.one })

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
				-- This step function runs at a variable frequency instead of
				-- the 120hz fixed frequency normally used in Vide
				step(1 / ITERATIONS)
			end

			cleanup()
			clear()
		end)
	end)
end

do
	local SpringValue = require("./react-flow/SpringValue")

	bench("react-flow", function()
		local spring = SpringValue.new(vector.zero, 1 / 10)

		spring:SetGoal(vector.one)
		spring:Run()

		for _ = 1, ITERATIONS do
			SpringValue.step(1 / ITERATIONS)
		end

		SpringValue.clear()
	end)
end
