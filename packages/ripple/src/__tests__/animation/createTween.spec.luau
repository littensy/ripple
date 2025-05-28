local createTween = require("../../animation/createTween")
local easing = require("../../easing")
local heartbeat = require("../../heartbeat")
local suite = require("../../../../../test/suite")

local test = suite.test

test("should have expected api", function()
	local tween = createTween(0)

	assert(type(tween.setPosition) == "function", "missing setPosition")
	assert(type(tween.setGoal) == "function", "missing setGoal")

	assert(type(tween.getPosition) == "function", "missing getPosition")
	assert(type(tween.getFrom) == "function", "missing getFrom")
	assert(type(tween.getGoal) == "function", "missing getGoal")

	assert(type(tween.onChange) == "function", "missing onChange")
	assert(type(tween.onComplete) == "function", "missing onComplete")

	assert(type(tween.step) == "function", "missing step")
	assert(type(tween.idle) == "function", "missing idle")
	assert(type(tween.configure) == "function", "missing configure")

	assert(type(tween.start) == "function", "missing start")
	assert(type(tween.stop) == "function", "missing stop")
	assert(type(tween.destroy) == "function", "missing destroy")
end)

test("should get properties", function()
	local tween = createTween(vector.one)

	assert(tween:getPosition() == vector.one, "invalid position")
	assert(tween:getFrom() == vector.one, "invalid from")
	assert(tween:getGoal() == vector.one, "invalid target")
	assert(tween:idle(), "invalid complete")
end)

test("should update properties", function()
	local tween = createTween(vector.zero)

	tween:setPosition(vector.one)
	tween:setGoal(vector.one)

	assert(tween:getPosition() == vector.one, "invalid position")
	assert(tween:getFrom() == tween:getPosition(), "invalid from")
	assert(tween:getGoal() == vector.one, "invalid target")
	assert(not tween:idle(), "invalid complete")
end)

test("should handle tables", function()
	local tween = createTween({ 0, 0, 0 })
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
	local tween = createTween(vector.one, { duration = 1 })

	tween:onComplete(function(value)
		result = value
	end)
	tween:setPosition(vector.zero)
	tween:step(0.5)

	assert(not tween:idle(), "invalid complete")
	assert(not result, "invalid result")
	assert(tween:getPosition() == vector.one / 2, "invalid position")
	assert(tween:getFrom() == vector.zero, "invalid from")

	tween:step(0.5)

	assert(tween:idle(), "invalid complete")
	assert(result == vector.one, "invalid result")
	assert(tween:getPosition() == vector.one, "invalid position")
	assert(tween:getFrom() == vector.zero, "invalid from")
end)

test("should start from new position", function()
	local result
	local tween = createTween(vector.one, { duration = 1 })

	tween:onComplete(function(value)
		result = value
	end)

	for _ = 1, 2 do
		tween:setPosition(vector.zero)
		tween:step(0.5)

		assert(not tween:idle(), "invalid complete")
		assert(not result, "invalid result")
		assert(tween:getPosition() == vector.one / 2, "invalid position")
		assert(tween:getFrom() == vector.zero, "invalid from")
	end

	tween:step(0.5)

	assert(tween:idle(), "invalid complete")
	assert(result == vector.one, "invalid result")
	assert(tween:getPosition() == vector.one, "invalid position")
	assert(tween:getFrom() == vector.zero, "invalid from")
end)

test("should connect while active", function()
	local tweens = {}
	for index = 1, 10 do
		tweens[index] = createTween(vector.zero, { start = true, duration = 1 })
	end
	assert(heartbeat.count() == 0, "start with 0 connections")

	for _ = 1, 2 do
		for _, tween in tweens do
			tween:setGoal(tween:getGoal() + vector.one)
		end
		assert(heartbeat.count() == #tweens, "connect on update")

		heartbeat.step(0.5)
		assert(heartbeat.count() == #tweens, "stay connected on partial step")

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
	local tween = createTween(vector.one, { duration = 1 })

	tween:onComplete(function(value)
		result = value
	end)

	for repeats, case in cases do
		tween:configure({ position = vector.zero, repeats = repeats })

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
	local tween = createTween(vector.one, { duration = 1 })

	tween:onComplete(function(value)
		result = value
	end)

	for repeats, case in cases do
		tween:configure({ position = vector.zero, repeats = repeats, reverses = true })

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

	local tween = createTween(0, { duration = 1 })
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
	local tween = createTween(1)

	for name in pairs(easing) do
		tween:configure({ position = 0, easing = name })
		local x0 = tween:step(0)
		local x1 = tween:step(1)
		assert(x0 == 0, `{name}(0) should be 0, got {x0}`)
		assert(x1 == 1, `{name}(1) should be 1, got {x1}`)
	end
end)

return {}
