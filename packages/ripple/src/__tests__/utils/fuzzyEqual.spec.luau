local fuzzyEqual = require("../../utils/fuzzyEqual")
local suite = require("../../../../../test/suite")

local test = suite.test

test("should be true for equal numbers", function()
	assert(fuzzyEqual(1, 1, 0.1), "expected fuzzyEqual to be true")
end)

test("should be true for equal vectors", function()
	assert(fuzzyEqual(vector.one, vector.one, 0.1), "expected fuzzyEqual to be true")
end)

test("should be true for numbers within the threshold", function()
	assert(fuzzyEqual(1, 1.099, 0.1), "expected fuzzyEqual to be true")
end)

test("should be true for vectors within the threshold", function()
	assert(fuzzyEqual(vector.one, vector.one * 1.099, 0.1), "expected fuzzyEqual to be true")
end)

test("should be false for numbers outside the threshold", function()
	assert(not fuzzyEqual(1, 1.101, 0.1), "expected fuzzyEqual to be false")
end)

test("should be false for vectors outside the threshold", function()
	assert(not fuzzyEqual(vector.one, vector.one * 1.101, 0.1), "expected fuzzyEqual to be false")
end)

test("should be inclusive of the threshold", function()
	assert(fuzzyEqual(1, 2, 1), "expected fuzzyEqual to be true")
	assert(fuzzyEqual(vector.one, vector.one * 2, 1), "expected fuzzyEqual to be true")
end)

return {}
