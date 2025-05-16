local createSpring = require("../../animation/createSpring")
local heartbeat = require("../../heartbeat")
local suite = require("../../../../../test/suite")

local test = suite.test

test("should get properties", function()
	local spring = createSpring(vector.one)

	assert(spring.position == vector.one, "invalid position")
	assert(spring.velocity == vector.zero, "invalid velocity")
	assert(spring.goal == vector.one, "invalid target")
	assert(spring.complete, "invalid complete")
end)

test("should update properties", function()
	local spring = createSpring(vector.zero)

	spring.position += vector.one
	spring.velocity += vector.one
	spring.goal -= vector.one

	assert(spring.position == vector.one, "invalid position")
	assert(spring.velocity == vector.one, "invalid velocity")
	assert(spring.goal == -vector.one, "invalid target")
	assert(not spring.complete, "invalid complete")
end)

test("should handle tables", function()
	local spring = createSpring({ 0, 0, 0 })
	local initialPosition = spring.position
	local initialVelocity = spring.velocity

	spring.position = { 0, 0, 0 }
	spring.velocity = { 0, 0, 0 }

	assert(spring.position == initialPosition, "unnecessary position copy")
	assert(spring.velocity == initialVelocity, "unnecessary velocity copy")

	spring.position = { [1] = 1, [3] = 1 }
	spring.velocity = { [1] = 1, [3] = 1 }

	assert(table.concat(spring.position) == "101", "did not merge position")
	assert(table.concat(spring.velocity) == "101", "did not merge velocity")
end)

test("should complete if goal is in reach", function()
	local result
	local spring = createSpring(vector.one, { precision = 0.5, restVelocity = 0.5 })

	spring.onComplete(function(value)
		result = value
	end)
	spring.position = vector.zero
	spring.step(0)

	assert(not spring.complete, "invalid complete")
	assert(not result, "invalid result")
	assert(spring.position == vector.zero, "invalid position")
	assert(spring.velocity == vector.zero, "invalid velocity")

	spring.position = vector.one / 2
	spring.velocity = vector.one / 2
	spring.step(0)

	assert(spring.complete, "invalid complete")
	assert(result == vector.one, "invalid result")
	assert(spring.position == vector.one, "invalid position")
	assert(spring.velocity == vector.zero, "invalid velocity")
end)

test("should connect while active", function()
	local springs = {}
	for index = 1, 10 do
		springs[index] = createSpring(vector.zero, { start = true, precision = 0.1 })
	end
	assert(heartbeat.count() == 0, "start with 0 connections")

	for _ = 1, 2 do
		for _, spring in springs do
			spring.goal += vector.one
		end
		assert(heartbeat.count() == #springs, "connect on update")

		heartbeat.step(1)
		assert(heartbeat.count() == #springs, "stay connected on partial step")

		heartbeat.step(1)
		assert(heartbeat.count() == 0, "disconnect on complete")
	end
end)

test("should wake after update on complete", function()
	local stepped = false
	local completes = 0

	local spring = createSpring(0, { precision = 0.1 })
	spring.goal = 1
	spring.onStep(function()
		stepped = true
	end)
	spring.onComplete(function()
		completes += 1
		if spring.goal ~= 0 then
			spring.goal = 0
			assert(not spring.complete, "did not uncomplete")
		end
	end)

	spring.step(2)
	assert(stepped, "did not step")
	assert(completes == 1, "did not complete")
	assert(not spring.complete, "did not uncomplete")

	stepped = false
	spring.step(1)
	assert(stepped, "did not step")
	assert(completes == 1, "completed for wrong goal")

	stepped = false
	spring.step(1)
	assert(stepped, "did not step")
	assert(completes == 2, "did not finally complete")
	assert(spring.complete, "did not complete")

	stepped = false
	spring.step(2)
	assert(not stepped, "stepped after complete")
	assert(completes == 2, "completed after completion")
end)

return {}
