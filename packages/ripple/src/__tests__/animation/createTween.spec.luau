local createTween = require("../../animation/createTween")
local easing = require("../../utils/easing")
local heartbeat = require("../../heartbeat")
local suite = require("../../../../../test/suite")

local test = suite.test

test("should get properties", function()
	local tween = createTween(vector.one)

	assert(tween.position == vector.one, "invalid position")
	assert(tween.from == vector.one, "invalid from")
	assert(tween.goal == vector.one, "invalid target")
	assert(tween.complete, "invalid complete")
end)

test("should update properties", function()
	local tween = createTween(vector.zero)

	tween.position += vector.one
	tween.goal -= vector.one

	assert(tween.position == vector.one, "invalid position")
	assert(tween.from == tween.position, "invalid from")
	assert(tween.goal == -vector.one, "invalid target")
	assert(not tween.complete, "invalid complete")
end)

test("should handle tables", function()
	local tween = createTween({ 0, 0, 0 })
	local initialPosition = tween.position
	local initialGoal = tween.goal

	tween.position = { 0, 0, 0 }
	tween.goal = { 0, 0, 0 }

	assert(tween.position == initialPosition, "unnecessary position copy")
	assert(tween.goal == initialGoal, "unnecessary goal copy")

	tween.position = { [1] = 1, [3] = 1 }
	tween.goal = { [1] = 1, [3] = 1 }

	assert(table.concat(tween.position) == "101", "did not merge position")
	assert(table.concat(tween.goal) == "101", "did not merge goal")
end)

test("should complete if duration passes", function()
	local result
	local tween = createTween(vector.one, { duration = 1 })

	tween.onComplete(function(value)
		result = value
	end)
	tween.position = vector.zero
	tween.step(0.5)

	assert(not tween.complete, "invalid complete")
	assert(not result, "invalid result")
	assert(tween.position == vector.one / 2, "invalid position")
	assert(tween.from == vector.zero, "invalid from")

	tween.step(0.5)

	assert(tween.complete, "invalid complete")
	assert(result == vector.one, "invalid result")
	assert(tween.position == vector.one, "invalid position")
	assert(tween.from == vector.zero, "invalid from")
end)

test("should start from new position", function()
	local result
	local tween = createTween(vector.one, { duration = 1 })

	tween.onComplete(function(value)
		result = value
	end)

	for _ = 1, 2 do
		tween.position = vector.zero
		tween.step(0.5)

		assert(not tween.complete, "invalid complete")
		assert(not result, "invalid result")
		assert(tween.position == vector.one / 2, "invalid position")
		assert(tween.from == vector.zero, "invalid from")
	end

	tween.step(0.5)

	assert(tween.complete, "invalid complete")
	assert(result == vector.one, "invalid result")
	assert(tween.position == vector.one, "invalid position")
	assert(tween.from == vector.zero, "invalid from")
end)

test("should connect while active", function()
	local tweens = {}
	for index = 1, 10 do
		tweens[index] = createTween(vector.zero, { start = true, duration = 1 })
	end
	assert(heartbeat.count() == 0, "start with 0 connections")

	for _ = 1, 2 do
		for _, tween in tweens do
			tween.goal += vector.one
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

	tween.onComplete(function(value)
		result = value
	end)

	for repeats, case in cases do
		tween.configure({ position = vector.zero, repeats = repeats })

		for i = 1, repeats * 2 do
			tween.step(0.5)
			assert(tween.position == vector.one * case[i], `{repeats} expected {case[i]}, got {tween.position}`)
		end

		assert(tween.complete, "did not complete")
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

	tween.onComplete(function(value)
		result = value
	end)

	for repeats, case in cases do
		tween.configure({ position = vector.zero, repeats = repeats, reverses = true })

		for i = 1, repeats * 2 do
			tween.step(0.5)
			assert(tween.position == vector.one * case[i], `{repeats} expected {case[i]}, got {tween.position}`)
		end

		assert(tween.complete, "did not complete")
		assert(result == vector.one * case[#case], `{repeats} expected {case[#case]}, got {result}`)
	end
end)

test("should wake after update on complete", function()
	local steps = 0
	local completes = 0

	local tween = createTween(0, { duration = 1 })
	tween.goal = 1
	tween.onStep(function()
		steps += 1
	end)
	tween.onComplete(function()
		completes += 1
		if tween.goal ~= 0 then
			tween.goal = 0
			assert(not tween.complete, "did not uncomplete")
		end
	end)

	tween.step(0.5)
	assert(steps == 1, "did not step")
	assert(completes == 0, "completed early")

	tween.step(0.5)
	assert(steps == 2, "did not step")
	assert(completes == 1, "did not complete")

	tween.step(0.5)
	assert(steps == 3, "did not step")
	assert(completes == 1, "completed early")

	tween.step(0.5)
	assert(steps == 4, "did not step")
	assert(completes == 2, "did not finally complete")
	assert(tween.complete, "did not complete")

	tween.step(0.5)
	assert(steps == 4, "stepped after complete")
	assert(completes == 2, "completed after complete")
end)

test("should have correct start and end", function()
	local tween = createTween(1)

	for name: easing.Easing in easing do
		tween.configure({ position = 0, easing = name })
		local x0 = tween.step(0)
		local x1 = tween.step(1)
		assert(x0 == 0, `{name}(0) should be 0, got {x0}`)
		assert(x1 == 1, `{name}(1) should be 1, got {x1}`)
	end
end)

return {}
