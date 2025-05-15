local fuzzyEqual = require("../../utils/fuzzyEqual")
local oklab = require("../../utils/oklab")
local suite = require("../../../../../test/suite")

local test = suite.test

local function testColors(callback: (vector) -> ())
	for r = 0, 4 do
		for g = 0, 4 do
			for b = 0, 4 do
				callback(vector.create(r, g, b) / 4)
			end
		end
	end
end

test("fromSRGB should match normal implementation", function()
	testColors(function(vec)
		local actual = oklab.fromSRGB(vec)
		local expected = oklab._fromSRGB(vec)
		assert(fuzzyEqual(actual, expected, 1e-4), `expected {actual} to be equal to {expected}`)
	end)
end)

test("toSRGB should match normal implementation", function()
	testColors(function(vec)
		local actual = oklab.toSRGB(vec)
		local expected = oklab._toSRGB(vec)
		assert(fuzzyEqual(actual, expected, 1e-4), `expected {actual} to be equal to {expected}`)
	end)
end)

test("should be reversible", function()
	testColors(function(vec)
		local lab = oklab.fromSRGB(vec)
		local rgb = oklab.toSRGB(lab)
		assert(fuzzyEqual(rgb, vec, 1e-4), `expected {rgb} to be equal to {vec}`)
	end)
end)

test("should not be nan for negative numbers", function()
	local lab = oklab.fromSRGB(-vector.one)
	assert(lab == lab, "expected output to not be NaN")
end)

return {}
