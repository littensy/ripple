local createSequence = require("../../animation/createSequence")
local suite = require("../../../../../test/suite")

local test = suite.test

test("should have expected api", function()
	local sequence = createSequence(0, {})

	assert(type(sequence.setTime) == "function", "missing setTime")
	assert(type(sequence.setPosition) == "function", "missing setPosition")
	assert(type(sequence.setVelocity) == "function", "missing setVelocity")

	assert(type(sequence.getTime) == "function", "missing getTime")
	assert(type(sequence.getPosition) == "function", "missing getPosition")
	assert(type(sequence.getVelocity) == "function", "missing getVelocity")

	assert(type(sequence.getGoal) == "function", "missing getGoal")
	assert(type(sequence.onChange) == "function", "missing onChange")
	assert(type(sequence.onComplete) == "function", "missing onComplete")
	assert(type(sequence.step) == "function", "missing step")
	assert(type(sequence.idle) == "function", "missing idle")

	assert(type(sequence.loop) == "function", "missing loop")
	assert(type(sequence.start) == "function", "missing start")
	assert(type(sequence.stop) == "function", "missing stop")
	assert(type(sequence.destroy) == "function", "missing destroy")
end)

test("should swap between spring and tween", function()
	local completions = 0
	local sequence = createSequence(vector.one, {
		{ time = 0, goal = vector.zero, spring = { precision = 0.1 } },
		{ time = 1, goal = vector.one, tween = { duration = 1 } },
		{ time = 2, goal = vector.zero, spring = { precision = 0.1 } },
	})

	sequence:onComplete(function()
		completions += 1
	end)
	sequence:step(0.1)
	assert(sequence:getPosition() ~= vector.one, "position should move toward keypoint 1")
	assert(sequence:getVelocity() ~= vector.zero, "velocity should not be zero")

	sequence:step(0.9)
	assert(sequence:getPosition() == vector.zero, "position should finish at keypoint 1")
	assert(sequence:getVelocity() == vector.zero, "velocity should be zero after completion")

	sequence:step(0.5)
	assert(sequence:getPosition() == vector.create(0.5, 0.5, 0.5), "position should be halfway to keypoint 2")
	assert(sequence:getVelocity() == vector.zero, "velocity should be zero during tween")

	sequence:step(0.5)
	assert(sequence:getPosition() == vector.one, "position should finish at keypoint 2")
	assert(sequence:getVelocity() == vector.zero, "velocity should be zero after completion")

	sequence:step(0.1)
	assert(sequence:getPosition() ~= vector.one, "position should start at keypoint 3")
	assert(sequence:getVelocity() ~= vector.zero, "velocity should not be zero")

	sequence:step(0.9)
	assert(completions == 1, "should have completed once")
	assert(sequence:getPosition() == vector.zero, "position should finish at keypoint 3")
	assert(sequence:getVelocity() == vector.zero, "velocity should be zero after completion")
end)

test("should persist interrupted tween config", function()
	local sequence = createSequence(0, {
		{ time = 0, goal = 1, tween = { duration = 2 } },
		{ time = 1, goal = 0 },
	})

	-- sequence 1 should end at 0.5 since it gets interrupted
	sequence:step(0.5)
	assert(sequence:getPosition() == 0.25, "should be 25% to keypoint 1")
	sequence:step(0.5)
	assert(sequence:getPosition() == 0.5, "should be 50% to keypoint 1")

	-- sequence 2 should tween from 0.5 to 0 for 2 seconds
	sequence:step(1)
	assert(sequence:getPosition() == 0.25, "should be 50% to keypoint 2")
	sequence:step(1)
	assert(sequence:getPosition() == 0, "should finish at keypoint 2")
	assert(sequence:idle(), "should be complete after finishing keypoint 2")
end)

test("should fire change with full state", function()
	local state = {}
	local sequence = createSequence({ 0, 0, 0 }, {})
	sequence:onChange(function(newState)
		state = newState
	end)

	sequence:setPosition({ 1, 1, 1 })
	assert(table.concat(state) == "111", "did not fire change with position")

	sequence:setPosition({ [1] = 2, [3] = 2 })
	assert(table.concat(state) == "212", "did not fire change with position merge")
end)

return {}
