local countAnimations = require("./helpers/countAnimations")
local createSpring = require("../createSpring")
local scheduler = require("../createSpring/scheduler")
local suite = require("../../../../test/suite")

local test = suite.test

test("should have expected api", function()
	local spring = createSpring(0)

	assert(type(spring.setPosition) == "function", "missing setPosition")
	assert(type(spring.setVelocity) == "function", "missing setVelocity")
	assert(type(spring.setGoal) == "function", "missing setGoal")

	assert(type(spring.getPosition) == "function", "missing getPosition")
	assert(type(spring.getVelocity) == "function", "missing getVelocity")
	assert(type(spring.getGoal) == "function", "missing getGoal")

	assert(type(spring.onChange) == "function", "missing onChange")
	assert(type(spring.onComplete) == "function", "missing onComplete")
	assert(type(spring.step) == "function", "missing step")
	assert(type(spring.impulse) == "function", "missing impulse")
	assert(type(spring.halt) == "function", "missing halt")
	assert(type(spring.idle) == "function", "missing idle")

	assert(type(spring.configure) == "function", "missing configure")
	assert(type(spring.start) == "function", "missing start")
	assert(type(spring.stop) == "function", "missing stop")
	assert(type(spring.destroy) == "function", "missing destroy")
end)

test("should get properties", function()
	local spring = createSpring(vector.one)

	assert(spring:getPosition() == vector.one, "invalid position")
	assert(spring:getVelocity() == vector.zero, "invalid velocity")
	assert(spring:getGoal() == vector.one, "invalid target")
	assert(spring:idle(), "invalid complete")
end)

test("should update properties", function()
	local spring = createSpring(vector.zero)

	spring:setPosition(vector.one)
	spring:setVelocity(vector.one)
	spring:setGoal(vector.one)

	assert(spring:getPosition() == vector.one, "invalid position")
	assert(spring:getVelocity() == vector.one, "invalid velocity")
	assert(spring:getGoal() == vector.one, "invalid target")
	assert(not spring:idle(), "invalid complete")
end)

test("should handle tables", function()
	local spring = createSpring({ 0, 0, 0 })
	local initialPosition = spring:getPosition()
	local initialVelocity = spring:getVelocity()

	spring:setPosition({ 0, 0, 0 })
	spring:setVelocity({ 0, 0, 0 })

	assert(spring:getPosition() == initialPosition, "unnecessary position copy")
	assert(spring:getVelocity() == initialVelocity, "unnecessary velocity copy")

	spring:setPosition({ [1] = 1, [3] = 1 })
	spring:setVelocity({ [1] = 1, [3] = 1 })

	assert(table.concat(spring:getPosition()) == "101", "did not merge position")
	assert(table.concat(spring:getVelocity()) == "101", "did not merge velocity")
end)

test("should complete if goal is in reach", function()
	local result
	local spring = createSpring(vector.one, { precision = 0.5, restVelocity = 0.5 })

	spring:onComplete(function(value)
		result = value
	end)
	spring:setPosition(vector.zero)
	spring:step(0)

	assert(not spring:idle(), "invalid complete")
	assert(not result, "invalid result")
	assert(spring:getPosition() == vector.zero, "invalid position")
	assert(spring:getVelocity() == vector.zero, "invalid velocity")

	spring:setPosition(vector.one / 2)
	spring:setVelocity(vector.one / 2)
	spring:step(0)

	assert(spring:idle(), "invalid complete")
	assert(result == vector.one, "invalid result")
	assert(spring:getPosition() == vector.one, "invalid position")
	assert(spring:getVelocity() == vector.zero, "invalid velocity")
end)

test("should connect while active", function()
	local springs = {}
	for index = 1, 10 do
		springs[index] = createSpring(vector.zero, { start = true, precision = 0.1 })
	end
	assert(countAnimations() == 0, "start with 0 connections")

	for _ = 1, 2 do
		for _, spring in springs do
			spring:setGoal(spring:getGoal() + vector.one)
		end
		assert(countAnimations() == #springs, "connect on update")

		scheduler.step(0.2)
		assert(countAnimations() == #springs, "stay connected on partial step")

		scheduler.step(0.5)
		assert(countAnimations() == 0, "disconnect on complete")
	end
end)

test("should wake after update on complete", function()
	local changed = false
	local completes = 0

	local spring = createSpring(0, { precision = 0.1 })
	spring:setGoal(1)
	spring:onChange(function()
		changed = true
	end)
	spring:onComplete(function()
		completes += 1
		if spring:getGoal() ~= 0 then
			spring:setGoal(0)
			assert(not spring:idle(), "did not uncomplete")
		end
	end)

	spring:step(1)
	assert(changed, "did not step")
	assert(completes == 1, "did not complete")
	assert(not spring:idle(), "did not uncomplete")

	changed = false
	spring:step(0.2)
	assert(changed, "did not step")
	assert(completes == 1, "completed for wrong goal")

	changed = false
	spring:step(0.2)
	assert(changed, "did not step")
	assert(completes == 2, "did not finally complete")
	assert(spring:idle(), "did not complete")

	changed = false
	spring:step(1)
	assert(not changed, "stepped after complete")
	assert(completes == 2, "completed after completion")
end)

test("should fire change with full state", function()
	local state = {}
	local spring = createSpring({ 0, 0, 0 })
	spring:onChange(function(newState)
		state = newState
	end)

	spring:setPosition({ 1, 1, 1 })
	assert(table.concat(state) == "111", "did not fire change with position")

	spring:setPosition({ [1] = 2, [3] = 2 })
	assert(table.concat(state) == "212", "did not fire change with position merge")
end)

return {}
