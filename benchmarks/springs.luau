local bench = require("./bench")

local FPS = 60
local SPRINGS = 100

do
	local createSpring = require("../packages/ripple/src/animation/createSpring")
	local heartbeat = require("../packages/ripple/src/heartbeat")

	local config = { start = true, stiffness = 1000, damping = 50 }

	bench("ripple", function()
		local springs = table.create(SPRINGS)

		for index = 1, SPRINGS do
			local spring = createSpring(0, config)
			spring.to(1)
			springs[index] = spring
		end

		for _ = 1, FPS do
			heartbeat.step(1 / FPS)
			for _, spring in springs do
				local _ = spring.position
			end
		end

		heartbeat.clear()
	end)
end

do
	local SpringValue = require("./react-flow/SpringValue")

	bench("react-flow", function()
		local springs = table.create(SPRINGS)

		for index = 1, SPRINGS do
			local spring = SpringValue.new(0, 1 / 50)
			spring:SetGoal(1)
			spring:Run()
			springs[index] = spring
		end

		for _ = 1, FPS do
			SpringValue.step(1 / FPS)
			for _, spring in springs do
				local _ = spring:GetValue()
			end
		end

		SpringValue.clear()
	end)
end

do
	local spring, step, clear = require("./vide/spring")()
	local root = require("./vide/root")

	local goal = function()
		return 1
	end

	bench("vide", function()
		local springs = table.create(SPRINGS)

		local cleanup = root(function()
			for index = 1, SPRINGS do
				local spring = spring(goal, 50)
				spring(0)
				springs[index] = spring
			end
		end)

		for _ = 1, FPS do
			step(1 / FPS)
			for _, spring in springs do
				local _ = spring()
			end
		end

		cleanup()
		clear()
	end)
end
