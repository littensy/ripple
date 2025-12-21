local easing = require("../easing")
local motion = require("../motion")
local test = require("../../../../tests/test")

local createMotion = motion.createMotion
local scheduler = motion.scheduler

test("should have expected api", function()
	local motion = createMotion(0)

	assert(type(motion.setPosition) == "function", "missing setPosition")
	assert(type(motion.setVelocity) == "function", "missing setVelocity")
	assert(type(motion.setGoal) == "function", "missing setGoal")

	assert(type(motion.getPosition) == "function", "missing getPosition")
	assert(type(motion.getVelocity) == "function", "missing getVelocity")
	assert(type(motion.getGoal) == "function", "missing getGoal")

	assert(type(motion.onChange) == "function", "missing onChange")
	assert(type(motion.onComplete) == "function", "missing onComplete")

	assert(type(motion.step) == "function", "missing step")
	assert(type(motion.spring) == "function", "missing spring")
	assert(type(motion.tween) == "function", "missing tween")
	assert(type(motion.idle) == "function", "missing idle")
	assert(type(motion.configure) == "function", "missing configure")

	assert(type(motion.start) == "function", "missing start")
	assert(type(motion.stop) == "function", "missing stop")
	assert(type(motion.destroy) == "function", "missing destroy")
end)

test("should swap from spring to tween", function()
	local completions = 0
	local motion = createMotion(vector.one)

	motion:onComplete(function()
		completions += 1
	end)
	motion:spring(vector.zero, { precision = 0.1 })
	motion:step(0.1)
	assert(completions == 0, "motion should be incomplete")
	assert(motion:getPosition() ~= vector.one, "position should change")
	assert(motion:getVelocity() ~= vector.zero, "velocity should not be zero")

	motion:step(0.9)
	assert(completions == 1, "motion should be complete")
	assert(motion:getPosition() == vector.zero, "position should finish")
	assert(motion:getVelocity() == vector.zero, "velocity should be zero after completion")

	motion:tween(vector.one, { duration = 1 })
	motion:step(0.5)
	assert(completions == 1, "motion should be incomplete")
	assert(motion:getPosition() == vector.create(0.5, 0.5, 0.5), "position should be halfway to goal")
	assert(motion:getVelocity() == vector.zero, "velocity should be zero during tween")

	motion:step(0.5)
	assert(completions == 2, "motion should be complete")
	assert(motion:getPosition() == vector.one, "position should finish at goal")
	assert(motion:getVelocity() == vector.zero, "velocity should be zero after completion")
end)

test("should swap from tween to spring", function()
	local completions = 0
	local motion = createMotion(vector.zero)

	motion:onComplete(function()
		completions += 1
	end)
	motion:tween(vector.one, { duration = 1 })
	motion:step(0.5)
	assert(completions == 0, "motion should be incomplete")
	assert(motion:getPosition() == vector.create(0.5, 0.5, 0.5), "position should be halfway to goal")
	assert(motion:getVelocity() == vector.zero, "velocity should be zero during tween")

	motion:step(0.5)
	assert(completions == 1, "motion should be complete")
	assert(motion:getPosition() == vector.one, "position should finish at goal")
	assert(motion:getVelocity() == vector.zero, "velocity should be zero after completion")

	motion:spring(vector.zero, { precision = 0.1 })
	motion:step(0.1)
	assert(completions == 1, "motion should be incomplete")
	assert(motion:getPosition() ~= vector.one, "position should change")
	assert(motion:getVelocity() ~= vector.zero, "velocity should not be zero")

	motion:step(0.9)
	assert(completions == 2, "motion should be complete")
	assert(motion:getPosition() == vector.zero, "position should finish")
	assert(motion:getVelocity() == vector.zero, "velocity should be zero after completion")
end)

test.describe("spring", function()
	test("should get properties", function()
		local spring = createMotion(vector.one)

		assert(spring:getPosition() == vector.one, "invalid position")
		assert(spring:getVelocity() == vector.zero, "invalid velocity")
		assert(spring:getGoal() == vector.one, "invalid target")
		assert(spring:idle(), "invalid complete")
	end)

	test("should update properties", function()
		local spring = createMotion(vector.zero)

		spring:setPosition(vector.one)
		spring:setVelocity(vector.one)
		spring:setGoal(vector.one)

		assert(spring:getPosition() == vector.one, "invalid position")
		assert(spring:getVelocity() == vector.one, "invalid velocity")
		assert(spring:getGoal() == vector.one, "invalid target")
		assert(not spring:idle(), "invalid complete")
	end)

	test("should handle tables", function()
		local spring = createMotion({ 0, 0, 0 })
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
		local spring = createMotion(vector.one, { spring = { precision = 0.5, restVelocity = 0.5 } })

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
			springs[index] = createMotion(vector.zero, { start = true, spring = { precision = 0.1 } })
		end
		assert(#scheduler.states == 0, "start with 0 connections")

		for _ = 1, 2 do
			for _, spring in springs do
				spring:setGoal(spring:getGoal() + vector.one)
			end
			assert(#scheduler.states == #springs, "connect on update")

			scheduler.step(0.2)
			assert(#scheduler.states == #springs, "stay connected on partial step")

			scheduler.step(0.5)
			assert(#scheduler.states == 0, "disconnect on complete")
		end
	end)

	test("should wake after update on complete", function()
		local changed = false
		local completes = 0

		local spring = createMotion(0, { spring = { precision = 0.1 } })
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
		local spring = createMotion({ 0, 0, 0 })
		spring:onChange(function(newState)
			state = newState
		end)

		spring:setPosition({ 1, 1, 1 })
		assert(table.concat(state) == "111", "did not fire change with position")

		spring:setPosition({ [1] = 2, [3] = 2 })
		assert(table.concat(state) == "212", "did not fire change with position merge")
	end)
end)

test.describe("tween", function()
	test("should get properties", function()
		local tween = createMotion(vector.one, { tween = {} })

		assert(tween:getPosition() == vector.one, "invalid position")
		assert(tween:getGoal() == vector.one, "invalid target")
		assert(tween:idle(), "invalid complete")
	end)

	test("should update properties", function()
		local tween = createMotion(vector.zero, { tween = {} })

		tween:setPosition(vector.one)
		tween:setGoal(vector.one)

		assert(tween:getPosition() == vector.one, "invalid position")
		assert(tween:getGoal() == vector.one, "invalid target")
		assert(not tween:idle(), "invalid complete")
	end)

	test("should handle tables", function()
		local tween = createMotion({ 0, 0, 0 }, { tween = {} })
		local initialPosition = tween:getPosition()
		local initialGoal = tween:getGoal()

		tween:setPosition({ 0, 0, 0 })
		tween:setGoal({ 0, 0, 0 })

		assert(tween:getPosition() == initialPosition, "unnecessary position copy")
		assert(tween:getGoal() == initialGoal, "unnecessary goal copy")

		tween:setPosition({ [1] = 1, [3] = 1 })
		tween:setGoal({ [1] = 1, [3] = 1 })

		assert(table.concat(tween:getPosition()) == "101", "did not merge position")
		assert(table.concat(tween:getGoal()) == "101", "did not merge goal")
	end)

	test("should complete if duration passes", function()
		local result
		local tween = createMotion(vector.one, { tween = { duration = 1 } })

		tween:onComplete(function(value)
			result = value
		end)
		tween:setPosition(vector.zero)
		tween:step(0.5)

		assert(not tween:idle(), "invalid complete")
		assert(not result, "invalid result")
		assert(tween:getPosition() == vector.one / 2, "invalid position")

		tween:step(0.5)

		assert(tween:idle(), "invalid complete")
		assert(result == vector.one, "invalid result")
		assert(tween:getPosition() == vector.one, "invalid position")
	end)

	test("should start from new position", function()
		local result
		local tween = createMotion(vector.one, { tween = { duration = 1 } })

		tween:onComplete(function(value)
			result = value
		end)

		for _ = 1, 2 do
			tween:setPosition(vector.zero)
			tween:step(0.5)

			assert(not tween:idle(), "invalid complete")
			assert(not result, "invalid result")
			assert(tween:getPosition() == vector.one / 2, "invalid position")
		end

		tween:step(0.5)

		assert(tween:idle(), "invalid complete")
		assert(result == vector.one, "invalid result")
		assert(tween:getPosition() == vector.one, "invalid position")
	end)

	test("should connect while active", function()
		local tweens = {}
		for index = 1, 10 do
			tweens[index] = createMotion(vector.zero, { start = true, tween = { duration = 1 } })
		end
		assert(#scheduler.states == 0, "start with 0 connections")

		for _ = 1, 2 do
			for _, tween in tweens do
				tween:setGoal(tween:getGoal() + vector.one)
			end
			assert(#scheduler.states == #tweens, "connect on update")

			scheduler.step(0.5)
			assert(#scheduler.states == #tweens, "stay connected on partial step")

			scheduler.step(0.5)
			assert(#scheduler.states == 0, "disconnect on complete")
		end
	end)

	test("should repeat", function()
		local cases = {
			[3] = { 0.5, 0, 0.5, 0, 0.5, 1 },
			[4] = { 0.5, 0, 0.5, 0, 0.5, 0, 0.5, 1 },
		}
		local result
		local tween = createMotion(vector.one, { tween = { duration = 1 } })

		tween:onComplete(function(value)
			result = value
		end)

		for repeats, case in cases do
			tween:configure({ tween = { position = vector.zero, repeats = repeats } })

			for i = 1, repeats * 2 do
				tween:step(0.5)
				assert(
					tween:getPosition() == vector.one * case[i],
					`{repeats} expected {case[i]}, got {tween:getPosition()}`
				)
			end

			assert(tween:idle(), "did not complete")
			assert(result == vector.one * case[#case], `{repeats} expected {case[#case]}, got {result}`)
		end
	end)

	test("should repeat in reverse", function()
		local cases = {
			[3] = { 0.5, 1, 0.5, 0, 0.5, 1 },
			[4] = { 0.5, 1, 0.5, 0, 0.5, 1, 0.5, 0 },
		}
		local result
		local tween = createMotion(vector.one, { tween = { duration = 1 } })

		tween:onComplete(function(value)
			result = value
		end)

		for repeats, case in cases do
			tween:configure({ tween = { position = vector.zero, repeats = repeats, reverses = true } })

			for i = 1, repeats * 2 do
				tween:step(0.5)
				assert(
					tween:getPosition() == vector.one * case[i],
					`{repeats} expected {case[i]}, got {tween:getPosition()}`
				)
			end

			assert(tween:idle(), "did not complete")
			assert(result == vector.one * case[#case], `{repeats} expected {case[#case]}, got {result}`)
		end
	end)

	test("should wake after update on complete", function()
		local changes = 0
		local completes = 0

		local tween = createMotion(0, { tween = { duration = 1 } })
		tween:setGoal(1)
		tween:onChange(function()
			changes += 1
		end)
		tween:onComplete(function()
			completes += 1
			if tween:getGoal() ~= 0 then
				tween:setGoal(0)
				assert(not tween:idle(), "did not uncomplete")
			end
		end)

		tween:step(0.5)
		assert(changes == 1, "did not step")
		assert(completes == 0, "completed early")

		tween:step(0.5)
		assert(changes == 2, "did not step")
		assert(completes == 1, "did not complete")

		tween:step(0.5)
		assert(changes == 3, "did not step")
		assert(completes == 1, "completed early")

		tween:step(0.5)
		assert(changes == 4, "did not step")
		assert(completes == 2, "did not finally complete")
		assert(tween:idle(), "did not complete")

		tween:step(0.5)
		assert(changes == 4, "stepped after complete")
		assert(completes == 2, "completed after complete")
	end)

	test("should have correct start and end", function()
		local tween = createMotion(1, { tween = {} })

		for name in pairs(easing) do
			tween:configure({ tween = { position = 0, easing = name } })
			local x0 = tween:step(0)
			local x1 = tween:step(1)
			assert(x0 == 0, `{name}(0) should be 0, got {x0}`)
			assert(x1 == 1, `{name}(1) should be 1, got {x1}`)
		end
	end)

	test("should fire change with full state", function()
		local state = {}
		local tween = createMotion({ 0, 0, 0 }, { tween = {} })
		tween:onChange(function(newState)
			state = newState
		end)

		tween:setPosition({ 1, 1, 1 })
		assert(table.concat(state) == "111", "did not fire change with position")

		tween:setPosition({ [1] = 2, [3] = 2 })
		assert(table.concat(state) == "212", "did not fire change with position merge")
	end)
end)

return {}
