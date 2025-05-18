local bench = require("./bench")

local ITERATIONS = 10000

-- selene: allow(unused_variable)
local object = {
	property = 0,
}

do
	local createSpring = require("../packages/ripple/src/animation/createSpring")
	local heartbeat = require("../packages/ripple/src/heartbeat")

	local config: createSpring.SpringConfig = { start = true, frequency = 1 / 10 }

	bench("ripple", function()
		local spring = createSpring(0, config)

		spring.to(1)
		spring.onChange(function(value)
			object.property = value
		end)

		for _ = 1, ITERATIONS do
			heartbeat.step(1 / ITERATIONS)
		end

		heartbeat.clear()
	end)
end

do
	local AnimationStepSignal = require("./otter/AnimationStepSignal")
	local createSingleMotor = require("./otter/createSingleMotor")
	local spring = require("./otter/spring")

	local config: spring.SpringOptions = { frequency = 1 / 10 }

	bench("otter", function()
		local motor = createSingleMotor(0)

		motor:setGoal(spring(1, config))
		motor:onStep(function(value)
			object.property = value
		end)

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
		return 1
	end

	bench("vide", function()
		root(function(cleanup)
			local spring = spring(goal, 10)
			spring(0)

			for _ = 1, ITERATIONS do
				-- This step function runs at a variable frequency instead of
				-- the 120hz fixed frequency normally used in Vide
				step(1 / ITERATIONS)
				-- Realistically, this should be in an effect, but including
				-- Vide's reactive graph is not the point of this benchmark
				object.property = spring()
			end

			cleanup()
			clear()
		end)
	end)
end

do
	local SpringValue = require("./react-flow/SpringValue")

	bench("react-flow", function()
		local spring = SpringValue.new(0, 1 / 10)

		spring:SetGoal(1)
		spring:Run()
		spring:SetUpdater(function(value)
			object.property = value
		end)

		for _ = 1, ITERATIONS do
			SpringValue.step(1 / ITERATIONS)
		end

		SpringValue.clear()
	end)
end
