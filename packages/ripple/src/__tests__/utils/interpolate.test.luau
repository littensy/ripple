local interpolate = require("../../utils/interpolate")
local test = require("../../../../../tests/test")

local cases: { { any } } = {
	{ 0, 1, 0.5 },
	{ vector.zero, vector.one, vector.create(0.5, 0.5, 0.5) },
	{ { 0, 0, 0 }, { 1, 1, 1 }, { 0.5, 0.5, 0.5 } },
}

if game then
	table.insert(cases, { Color3.new(), Color3.new(1, 1, 1) }) -- Just check if the result is a Color3
	table.insert(cases, { UDim2.new(0, 0, 0, 0), UDim2.new(1, 100, 1, 100), UDim2.new(0.5, 50, 0.5, 50) })
	table.insert(cases, { UDim.new(0, 0), UDim.new(1, 100), UDim.new(0.5, 50) })
	table.insert(cases, { Rect.new(0, 0, 0, 0), Rect.new(100, 100, 200, 200), Rect.new(50, 50, 100, 100) })
	table.insert(cases, { CFrame.new(0, 0, 0), CFrame.new(10, 10, 10), CFrame.new(5, 5, 5) })
end

for _, case in cases do
	local a, b, expected = unpack(case)

	test(`should return correct type for {typeof(a)}`, function()
		local result = interpolate(a, b, 0.5)
		assert(typeof(result) == typeof(a), `Expected type {typeof(a)}, got {typeof(result)}`)
	end)

	if not expected then
		continue
	end

	test(`should return correct midpoint for {typeof(a)}`, function()
		local result = interpolate(a, b, 0.5)

		if type(result) == "table" then
			for key, value in expected do
				assert(result[key] == value, `Expected {value} at index {key}, got {result[key]}`)
			end
		else
			assert(result == expected, `Expected {expected}, got {result}`)
		end
	end)
end

test("should return original table if nothing changed", function()
	local input = { 1 }
	assert(interpolate(input, { 2 }, 0) == input, "Expected the same table for step 0")
	assert(interpolate(input, { 1 }, 1) == input, "Expected the same table for step to same value")
end)

return {}
