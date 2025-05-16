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

local function fuzzyEqual(a: vector, b: vector): boolean
	local abs = vector.abs(a - b)
	return math.max(abs.x, abs.y, abs.z) < 1e-4
end

test("should be reversible lab to rgb", function()
	testColors(function(vec)
		local lab = oklab.fromSRGB(vec)
		local rgb = oklab.toSRGB(lab)
		assert(fuzzyEqual(rgb, vec), `expected {rgb} to be equal to {vec}`)
	end)
end)

test("should be reversible rgb to lab", function()
	testColors(function(vec)
		local rgb = oklab.toSRGB(vec)
		local lab = oklab.fromSRGB(rgb)
		assert(fuzzyEqual(lab, vec), `expected {lab} to be equal to {vec}`)
	end)
end)

test("should not be nan for negative numbers", function()
	local lab = oklab.fromSRGB(-vector.one)
	assert(lab == lab, "expected output to not be NaN")
end)

return {}
