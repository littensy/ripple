local createMotion = require("../../animation/createMotion")
local heartbeat = require("../../heartbeat")
local suite = require("../../../../../test/suite")

local describe = suite.describe
local test = suite.test

test("should swap from spring to tween", function()
	local completions = 0
	local motion = createMotion(vector.one)

	motion.onComplete(function()
		completions += 1
	end)
	motion.spring(vector.zero, { precision = 0.1 })
	motion.step(0.1)
	assert(completions == 0, "motion should be incomplete")
	assert(motion.position ~= vector.one, "position should change")
	assert(motion.velocity ~= vector.zero, "velocity should not be zero")

	motion.step(0.9)
	assert(completions == 1, "motion should be complete")
	assert(motion.position == vector.zero, "position should finish")
	assert(motion.velocity == vector.zero, "velocity should be zero after completion")

	motion.tween(vector.one, { duration = 1 })
	motion.step(0.5)
	assert(completions == 1, "motion should be incomplete")
	assert(motion.position == vector.create(0.5, 0.5, 0.5), "position should be halfway to goal")
	assert(motion.velocity == vector.zero, "velocity should be zero during tween")

	motion.step(0.5)
	assert(completions == 2, "motion should be complete")
	assert(motion.position == vector.one, "position should finish at goal")
	assert(motion.velocity == vector.zero, "velocity should be zero after completion")
end)

test("should swap from tween to spring", function()
	local completions = 0
	local motion = createMotion(vector.zero)

	motion.onComplete(function()
		completions += 1
	end)
	motion.tween(vector.one, { duration = 1 })
	motion.step(0.5)
	assert(completions == 0, "motion should be incomplete")
	assert(motion.position == vector.create(0.5, 0.5, 0.5), "position should be halfway to goal")
	assert(motion.velocity == vector.zero, "velocity should be zero during tween")

	motion.step(0.5)
	assert(completions == 1, "motion should be complete")
	assert(motion.position == vector.one, "position should finish at goal")
	assert(motion.velocity == vector.zero, "velocity should be zero after completion")

	motion.spring(vector.zero, { precision = 0.1 })
	motion.step(0.1)
	assert(completions == 1, "motion should be incomplete")
	assert(motion.position ~= vector.one, "position should change")
	assert(motion.velocity ~= vector.zero, "velocity should not be zero")

	motion.step(0.9)
	assert(completions == 2, "motion should be complete")
	assert(motion.position == vector.zero, "position should finish")
	assert(motion.velocity == vector.zero, "velocity should be zero after completion")
end)

describe("spring", function()
	test("should get properties", function()
		local motion = createMotion(vector.one)

		assert(motion.position == vector.one, "invalid position")
		assert(motion.velocity == vector.zero, "invalid velocity")
		assert(motion.goal == vector.one, "invalid target")
		assert(motion.complete, "invalid complete")
	end)

	test("should update properties", function()
		local motion = createMotion(vector.zero)

		motion.position += vector.one
		motion.velocity += vector.one
		motion.goal -= vector.one

		assert(motion.position == vector.one, "invalid position")
		assert(motion.velocity == vector.one, "invalid velocity")
		assert(motion.goal == -vector.one, "invalid target")
		assert(not motion.complete, "invalid complete")
	end)

	test("should handle tables", function()
		local motion = createMotion({ 0, 0, 0 })
		local initialPosition = motion.position
		local initialVelocity = motion.velocity

		motion.position = { 0, 0, 0 }
		motion.velocity = { 0, 0, 0 }

		assert(motion.position == initialPosition, "unnecessary position copy")
		assert(motion.velocity == initialVelocity, "unnecessary velocity copy")

		motion.position = { [1] = 1, [3] = 1 }
		motion.velocity = { [1] = 1, [3] = 1 }

		assert(table.concat(motion.position) == "101", "did not merge position")
		assert(table.concat(motion.velocity) == "101", "did not merge velocity")
	end)

	test("should complete if goal is in reach", function()
		local result
		local motion = createMotion(vector.zero)

		motion.onComplete(function(value)
			result = value
		end)
		motion.spring(vector.one, { precision = 0.5, restVelocity = 0.5 })
		motion.step(0)

		assert(not motion.complete, "invalid complete")
		assert(not result, "invalid result")
		assert(motion.position == vector.zero, "invalid position")
		assert(motion.velocity == vector.zero, "invalid velocity")

		motion.position = vector.one / 2
		motion.velocity = vector.one / 2
		motion.step(0)

		assert(motion.complete, "invalid complete")
		assert(result == vector.one, "invalid result")
		assert(motion.position == vector.one, "invalid position")
		assert(motion.velocity == vector.zero, "invalid velocity")
	end)

	test("should connect while active", function()
		local motions = {}
		for index = 1, 10 do
			motions[index] = createMotion(vector.zero, { type = "spring", start = true, precision = 0.1 })
		end
		assert(heartbeat.count() == 0, "start with 0 connections")

		for _ = 1, 2 do
			for _, motion in motions do
				motion.goal += vector.one
			end
			assert(heartbeat.count() == #motions, "connect on update")

			heartbeat.step(0.2)
			assert(heartbeat.count() == #motions, "stay connected on partial step")

			heartbeat.step(0.5)
			assert(heartbeat.count() == 0, "disconnect on complete")
		end
	end)

	test("should wake after update on complete", function()
		local changed = false
		local completes = 0

		local motion = createMotion(0)
		motion.spring(1, { precision = 0.1 })
		motion.onChange(function()
			changed = true
		end)
		motion.onComplete(function()
			completes += 1
			if motion.goal ~= 0 then
				motion.goal = 0
				assert(not motion.complete, "did not uncomplete")
			end
		end)

		motion.step(1)
		assert(changed, "did not step")
		assert(completes == 1, "did not complete")
		assert(not motion.complete, "did not uncomplete")

		changed = false
		motion.step(0.2)
		assert(changed, "did not step")
		assert(completes == 1, "completed for wrong goal")

		changed = false
		motion.step(0.2)
		assert(changed, "did not step")
		assert(completes == 2, "did not finally complete")
		assert(motion.complete, "did not complete")

		changed = false
		motion.step(1)
		assert(not changed, "stepped after complete")
		assert(completes == 2, "completed after completion")
	end)
end)

describe("tween", function()
	test("should get properties", function()
		local motion = createMotion(vector.one, { type = "tween", duration = 1 })

		assert(motion.position == vector.one, "invalid position")
		assert(motion.goal == vector.one, "invalid target")
		assert(motion.complete, "invalid complete")
	end)

	test("should update properties", function()
		local motion = createMotion(vector.zero, { type = "tween", duration = 1 })

		motion.position += vector.one
		motion.goal -= vector.one

		assert(motion.position == vector.one, "invalid position")
		assert(motion.goal == -vector.one, "invalid target")
		assert(not motion.complete, "invalid complete")
	end)

	test("should handle tables", function()
		local motion = createMotion({ 0, 0, 0 }, { type = "tween", duration = 1 })
		local initialPosition = motion.position
		local initialGoal = motion.goal

		motion.position = { 0, 0, 0 }
		motion.goal = { 0, 0, 0 }

		assert(motion.position == initialPosition, "unnecessary position copy")
		assert(motion.goal == initialGoal, "unnecessary goal copy")

		motion.position = { [1] = 1, [3] = 1 }
		motion.goal = { [1] = 1, [3] = 1 }

		assert(table.concat(motion.position) == "101", "did not merge position")
		assert(table.concat(motion.goal) == "101", "did not merge goal")
	end)

	test("should complete if duration passes", function()
		local result
		local motion = createMotion(vector.one, { type = "tween", duration = 1 })

		motion.onComplete(function(value)
			result = value
		end)
		motion.position = vector.zero
		motion.step(0.5)

		assert(not motion.complete, "invalid complete")
		assert(not result, "invalid result")
		assert(motion.position == vector.one / 2, "invalid position")

		motion.step(0.5)

		assert(motion.complete, "invalid complete")
		assert(result == vector.one, "invalid result")
		assert(motion.position == vector.one, "invalid position")
	end)

	test("should start from new position", function()
		local result
		local motion = createMotion(vector.one, { type = "tween", duration = 1 })

		motion.onComplete(function(value)
			result = value
		end)

		for _ = 1, 2 do
			motion.position = vector.zero
			motion.step(0.5)

			assert(not motion.complete, "invalid complete")
			assert(not result, "invalid result")
			assert(motion.position == vector.one / 2, "invalid position")
		end

		motion.step(0.5)

		assert(motion.complete, "invalid complete")
		assert(result == vector.one, "invalid result")
		assert(motion.position == vector.one, "invalid position")
	end)

	test("should connect while active", function()
		local motions = {}
		for index = 1, 10 do
			motions[index] = createMotion(vector.zero, { type = "tween", start = true, duration = 1 })
		end
		assert(heartbeat.count() == 0, "start with 0 connections")

		for _ = 1, 2 do
			for _, motion in motions do
				motion.goal += vector.one
			end
			assert(heartbeat.count() == #motions, "connect on update")

			heartbeat.step(0.5)
			assert(heartbeat.count() == #motions, "stay connected on partial step")

			heartbeat.step(0.5)
			assert(heartbeat.count() == 0, "disconnect on complete")
		end
	end)

	test("should repeat", function()
		local cases = {
			[3] = { 0.5, 0, 0.5, 0, 0.5, 1 },
			[4] = { 0.5, 0, 0.5, 0, 0.5, 0, 0.5, 1 },
		}
		local result
		local motion = createMotion(vector.one, { type = "tween", duration = 1 })

		motion.onComplete(function(value)
			result = value
		end)

		for repeats, case in cases do
			motion.configure({ type = "tween", position = vector.zero, repeats = repeats })

			for i = 1, repeats * 2 do
				motion.step(0.5)
				assert(motion.position == vector.one * case[i], `{repeats} expected {case[i]}, got {motion.position}`)
			end

			assert(motion.complete, "did not complete")
			assert(result == vector.one * case[#case], `{repeats} expected {case[#case]}, got {result}`)
		end
	end)

	test("should repeat in reverse", function()
		local cases = {
			[3] = { 0.5, 1, 0.5, 0, 0.5, 1 },
			[4] = { 0.5, 1, 0.5, 0, 0.5, 1, 0.5, 0 },
		}
		local result
		local motion = createMotion(vector.one, { type = "tween", duration = 1 })

		motion.onComplete(function(value)
			result = value
		end)

		for repeats, case in cases do
			motion.configure({
				type = "tween",
				position = vector.zero,
				repeats = repeats,
				reverses = true,
			})

			for i = 1, repeats * 2 do
				motion.step(0.5)
				assert(motion.position == vector.one * case[i], `{repeats} expected {case[i]}, got {motion.position}`)
			end

			assert(motion.complete, "did not complete")
			assert(result == vector.one * case[#case], `{repeats} expected {case[#case]}, got {result}`)
		end
	end)

	test("should wake after update on complete", function()
		local changes = 0
		local completes = 0

		local motion = createMotion(0, { type = "tween", duration = 1 })
		motion.goal = 1
		motion.onChange(function()
			changes += 1
		end)
		motion.onComplete(function()
			completes += 1
			if motion.goal ~= 0 then
				motion.goal = 0
				assert(not motion.complete, "did not uncomplete")
			end
		end)

		motion.step(0.5)
		assert(changes == 1, "did not step")
		assert(completes == 0, "completed early")

		motion.step(0.5)
		assert(changes == 2, "did not step")
		assert(completes == 1, "did not complete")

		motion.step(0.5)
		assert(changes == 3, "did not step")
		assert(completes == 1, "completed early")

		motion.step(0.5)
		assert(changes == 4, "did not step")
		assert(completes == 2, "did not finally complete")
		assert(motion.complete, "did not complete")

		motion.step(0.5)
		assert(changes == 4, "stepped after complete")
		assert(completes == 2, "completed after complete")
	end)
end)

return {}
