local HttpService = game:GetService("HttpService")

local types = require(script.Parent.Parent.types)
local createMotion = require(script.Parent.Parent.createMotion)

local STEP = 0.1
local MAX_LENGTH = 20

local function createSnapshot(solver: types.MotionSolver, length: number?)
	local data: { number } = {}
	local motion = createMotion(0)

	motion:to(solver)

	for _ = 1, length or MAX_LENGTH do
		local value = motion:step(STEP)

		value = if value < 1
			then math.floor(value * 100) / 100
			elseif value > 1 then math.ceil(value * 100) / 100
			else value

		table.insert(data, value)

		if value == 1 then
			break
		end
	end

	return HttpService:JSONEncode(data), motion
end

local function testSnapshot(solver: types.MotionSolver, expected: string)
	local length = select(2, string.gsub(expected, ",", ",")) + 1
	local snapshot, motion = createSnapshot(solver, length)

	if snapshot ~= expected then
		error(`Snapshot does not match expected value.\n\nExpected:\n{expected}\n\nActual:\n{snapshot}`, 2)
	end

	return motion
end

return {
	createSnapshot = createSnapshot,
	testSnapshot = testSnapshot,
}
