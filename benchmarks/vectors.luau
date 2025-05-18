local bench = require("./bench")

local ITERATIONS = 10000

-- selene: allow(unused_variable)
local object = {
	property = vector.zero,
}

do
	local createSpring = require("../packages/ripple/src/animation/createSpring")
	local heartbeat = require("../packages/ripple/src/heartbeat")

	local config = { start = true, frequency = 1 / 10 }

	bench("ripple", function()
		local spring = createSpring(vector.zero, config)

		spring.to(vector.one)
		spring.onStep(function(value)
			object.property = value
		end)

		for _ = 1, ITERATIONS do
			heartbeat.step(1 / ITERATIONS)
		end

		heartbeat.clear()
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
			local spring = spring(goal, 10)
			spring(vector.zero)

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
	local AnimationStepSignal = require("./otter/AnimationStepSignal")
	local createGroupMotor = require("./otter/createGroupMotor")
	local spring = require("./otter/spring")

	local config = { frequency = 1 / 10 }

	bench("otter", function()
		local motor = createGroupMotor({ x = 0, y = 0, z = 0 })

		motor:setGoal({
			x = spring(1, config),
			y = spring(1, config),
			z = spring(1, config),
		})

		motor:onStep(function(value)
			object.property = vector.create(value.x, value.y, value.z)
		end)

		for _ = 1, ITERATIONS do
			AnimationStepSignal:Fire(1 / ITERATIONS)
		end

		AnimationStepSignal:Clear()
	end)
end

do
	local SpringValue = require("./react-flow/SpringValue")

	bench("react-flow", function()
		local spring = SpringValue.new(vector.zero, 1 / 10)

		spring:SetGoal(vector.one)
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
