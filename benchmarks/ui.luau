--[[
	Each benchmark runs a prolonged spring animation that updates a property
	a specified number of times, measuring the performance of each library.

	Updates are managed through Vide effects to simulate a real-world scenario
	where the developer is using these libraries to animate an object created
	with Vide.
]]

local bench = require("./bench")
local effect = require("./vide/effect")
local root = require("./vide/root")
local source = require("./vide/source")

local ITERATIONS = 10000

-- selene: allow(unused_variable)
local object = {
	property = 0,
}

do
	local createSpring = require("../packages/ripple/src/animation/createSpring")
	local heartbeat = require("../packages/ripple/src/heartbeat")

	local config: createSpring.SpringConfig = {
		start = true,
		frequency = 1 / 10,
	}

	bench("ripple", function()
		root(function(cleanup)
			local spring = createSpring(0, config)
			local src = source(0)

			effect(function()
				object.property = src()
			end)

			spring.to(1)
			spring.onChange(src)

			for _ = 1, ITERATIONS do
				heartbeat.step(1 / ITERATIONS)
			end

			heartbeat.clear()
			cleanup()
		end)
	end)
end

do
	local AnimationStepSignal = require("./otter/AnimationStepSignal")
	local createSingleMotor = require("./otter/createSingleMotor")
	local spring = require("./otter/spring")

	local config: spring.SpringOptions = { frequency = 1 / 10 }

	bench("otter", function()
		root(function(cleanup)
			local motor = createSingleMotor(0)
			local src = source(0)

			effect(function()
				object.property = src()
			end)

			motor:setGoal(spring(1, config))
			motor:onStep(src)

			for _ = 1, ITERATIONS do
				AnimationStepSignal:Fire(1 / ITERATIONS)
			end

			AnimationStepSignal:Clear()
			cleanup()
		end)
	end)
end

do
	local spring, step, clear = require("./vide/spring")()

	local function goal()
		return 1
	end

	bench("vide", function()
		root(function(cleanup)
			local spring = spring(goal, 10)

			effect(function()
				object.property = spring()
			end)

			spring(0)

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
		root(function(cleanup)
			local spring = SpringValue.new(0, 1 / 10)
			local src = source(0)

			effect(function()
				object.property = src()
			end)

			spring:SetGoal(1)
			spring:Run()
			spring:SetUpdater(src)

			for _ = 1, ITERATIONS do
				SpringValue.step(1 / ITERATIONS)
			end

			SpringValue.clear()
			cleanup()
		end)
	end)
end
