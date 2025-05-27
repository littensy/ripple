local createSequence = require("../../animation/createSequence")
local suite = require("../../../../../test/suite")

local test = suite.test

test("should swap between spring and tween", function()
	local completions = 0
	local sequence = createSequence(vector.one, {
		{ time = 0, goal = vector.zero, spring = { precision = 0.1 } },
		{ time = 1, goal = vector.one, tween = { duration = 1 } },
		{ time = 2, goal = vector.zero, spring = { precision = 0.1 } },
	})

	sequence.onComplete(function()
		completions += 1
	end)
	sequence.step(0.1)
	assert(sequence.position ~= vector.one, "position should start keypoint 3")
	assert(sequence.velocity ~= vector.zero, "velocity should not be zero")

	sequence.step(0.9)
	assert(sequence.position == vector.zero, "position should finish at keypoint 1")
	assert(sequence.velocity == vector.zero, "velocity should be zero after completion")

	sequence.step(0.5)
	assert(sequence.position == vector.create(0.5, 0.5, 0.5), "position should be halfway to keypoint 2")
	assert(sequence.velocity == vector.zero, "velocity should be zero during tween")

	sequence.step(0.5)
	assert(sequence.position == vector.one, "position should finish at keypoint 2")
	assert(sequence.velocity == vector.zero, "velocity should be zero after completion")

	sequence.step(0.1)
	assert(sequence.position ~= vector.one, "position should start keypoint 3")
	assert(sequence.velocity ~= vector.zero, "velocity should not be zero")

	sequence.step(0.9)
	assert(completions == 1, "should have completed once")
	assert(sequence.position == vector.zero, "position should finish at keypoint 3")
	assert(sequence.velocity == vector.zero, "velocity should be zero after completion")
end)

test("should persist interrupted tween config", function()
	local sequence = createSequence(0, {
		{ time = 0, goal = 1, tween = { duration = 2 } },
		{ time = 1, goal = 0 },
	})

	-- sequence 1 should end at 0.5 since it gets interrupted
	sequence.step(0.5)
	assert(sequence.position == 0.25, "should be 25% to keypoint 1")
	sequence.step(0.5)
	assert(sequence.position == 0.5, "should be 50% to keypoint 1")

	-- sequence 2 should tween from 0.5 to 0 for 2 seconds
	sequence.step(1)
	assert(sequence.position == 0.25, "should be 50% to keypoint 2")
	sequence.step(1)
	assert(sequence.position == 0, "should finish at keypoint 2")
	assert(sequence.idle(), "should be complete after finishing keypoint 2")
end)

return {}
