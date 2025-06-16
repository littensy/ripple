local scheduler = require("../createSpring/scheduler")
local spr = require("../spr")
local suite = require("../../../../test/suite")

local beforeEach = suite.beforeEach
local test = suite.test

beforeEach(function()
	scheduler.clear()
	table.clear(spr.objects)
end)

test("should update properties", function()
	local instance = { value = 0 }

	spr.target(instance, {}, { value = 1 })

	local state = spr.objects[instance]
	assert(state, "state should not be nil")
	assert(state.springs.value, "spring should be created for property 'value'")
	assert(state.springs.value:getPosition() == 0, "spring should start at 0")
	assert(state.springs.value:getGoal() == 1, "spring should have a goal of 1")

	scheduler.step(0.1)
	assert(state.springs.value:getPosition() > 0, "spring should move towards goal")
	assert(instance.value == state.springs.value:getPosition(), "instance value should be updated")

	scheduler.step(1)
	assert(not state.springs.value, "spring should be removed after reaching goal")
	assert(instance.value == 1, "instance value should equal goal")
	assert(next(spr.objects) == nil, "no springs should remain in state after completion")
end)

test("should run completed callback", function()
	local calls = 0
	local instance = { value = 0 }

	spr.target(instance, {}, { value = 1 })
	spr.completed(instance, function()
		calls += 1
	end)

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
	spr.configure({}, {})
	spr.completed({}, function() end)
	assert(next(spr.objects) == nil, "objects should be empty when no properties are set")
end)

test("should configure properties", function()
	local instance = { x = 0, y = 0 }

	spr.target(instance, {}, { x = 1 })
	spr.configure(instance, { velocity = 1 }, { "x" })
	spr.configure(instance, { velocity = 2 }, { "y" })

	local state = spr.objects[instance]
	assert(state, "state should not be nil")
	assert(state.springs.x, "spring should be created for property 'x'")
	assert(state.springs.y, "spring should be created for property 'y'")
	assert(state.springs.x:getVelocity() == 1, "spring 'x' should have velocity of 1")
	assert(state.springs.y:getVelocity() == 2, "spring 'y' should have velocity of 2")
end)

test("should cancel animation", function()
	local instance = { value = 0 }

	spr.target(instance, {}, { value = 1 })
	spr.completed(instance, function() end)()

	local state = spr.objects[instance]
	assert(state, "state should not be nil")

	local spring = state.springs.value
	assert(spring, "spring should exist before cancellation")

	spr.stop(instance)
	assert(not spring.state.started, "spring should not be started after cancellation")
	assert(next(spr.objects) == nil, "no springs should remain in state after cancellation")
end)

return {}
