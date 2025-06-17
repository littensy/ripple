local scheduler = require("../createSpring/scheduler")
local spr = require("../spr")
local suite = require("../../../../test/suite")

local beforeEach = suite.beforeEach
local test = suite.test

beforeEach(function()
	scheduler.clear()
	table.clear(spr.springStates)
	table.clear(spr.completedCallbacks)
end)

test("should update properties", function()
	local instance = { value = 0 }

	spr.target(instance, {}, { value = 1 })
	local state = spr.springStates[instance]
	assert(state, "state should not be nil")
	assert(state.value, "spring should be created for property 'value'")
	assert(state.value:getPosition() == 0, "spring should start at 0")
	assert(state.value:getGoal() == 1, "spring should have a goal of 1")

	scheduler.step(0.1)
	assert(state.value:getPosition() > 0, "spring should move towards goal")
	assert(instance.value == state.value:getPosition(), "instance value should be updated")

	scheduler.step(1)
	assert(not state.value, "spring should be removed after reaching goal")
	assert(instance.value == 1, "instance value should equal goal")
	assert(next(spr.springStates) == nil, "no springs should remain in state after completion")
end)

test("should skip unnecessary updates", function()
	local instance = { value = 1 }

	spr.target(instance, {}, { value = 1 })
	assert(not spr.springStates[instance], "state should be nil")

	spr.target(instance, { velocity = 1 }, { value = 1 })
	assert(spr.springStates[instance], "state should not be nil")
end)

test("should run completed callback", function()
	local calls = 0
	local instance = { value = 0 }

	spr.completed(instance, function()
		calls += 1
	end)
	spr.target(instance, {}, { value = 1 })

	scheduler.step(0.1)
	assert(instance.value > 0, "instance value should be updated")
	assert(calls == 0, "callback should not have run")

	scheduler.step(1)
	assert(instance.value == 1, "instance value should equal goal")
	assert(calls == 1, "callback should have run once after completion")
end)

test("should run completed callback on cancel", function()
	local calls = 0
	local instance = { value = 0 }

	spr.target(instance, {}, { value = 1 })
	spr.completed(instance, function()
		calls += 1
	end)

	scheduler.step(0.1)
	assert(instance.value > 0, "instance value should be updated")
	assert(calls == 0, "callback should not have run")

	spr.stop(instance)
	assert(instance.value ~= 1, "instance value should not equal goal")
	assert(calls == 1, "callback should have run once after completion")
end)

test("should dispose completed callback", function()
	local calls = 0
	local instance = { value = 0 }

	spr.target(instance, {}, { value = 1 })
	spr.completed(instance, function()
		error("completed should not run after cancellation")
	end)()
	spr.completed(instance, function()
		calls += 1
	end)

	scheduler.step(1)
	assert(instance.value == 1, "instance value should equal goal")
	assert(calls == 1, "callback should have run once after completion")
end)

test("should not create empty states", function()
	spr.target({}, {}, {})
	spr.update({}, {}, {})
	spr.completed({}, function() end)
	assert(next(spr.springStates) == nil, "objects should be empty when no properties are set")
end)

test("should configure properties", function()
	local instance = { x = 0, y = 0 }

	spr.target(instance, {}, { x = 1 })
	spr.update(instance, { velocity = 1 }, { "x" })
	spr.update(instance, { velocity = 2 }, { "y" })

	local state = spr.springStates[instance]
	assert(state, "state should not be nil")
	assert(state.x, "spring should be created for property 'x'")
	assert(state.y, "spring should be created for property 'y'")
	assert(state.x:getVelocity() == 1, "spring 'x' should have velocity of 1")
	assert(state.y:getVelocity() == 2, "spring 'y' should have velocity of 2")
end)

test("should cancel animation", function()
	local instance = { value = 0 }

	spr.target(instance, {}, { value = 1 })
	spr.completed(instance, function() end)

	local state = spr.springStates[instance]
	assert(state, "state should not be nil")

	local spring = state.value
	assert(spring, "spring should exist before cancellation")

	spr.stop(instance)
	assert(not spring.state.started, "spring should not be started after cancellation")
	assert(next(spr.springStates) == nil, "no springs should remain in state after cancellation")
	assert(next(spr.completedCallbacks) == nil, "no completed callbacks should remain after cancellation")
end)

return {}
