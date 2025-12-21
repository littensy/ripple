local easing = require("../easing")
local test = require("../../../../tests/test")

test("should have correct start and end", function()
	for name, easingFunction in pairs(easing) do
		local x0 = easingFunction(0)
		local x1 = easingFunction(1)
		assert(math.abs(x0) < 1e-4, `{name}(0) should be near 0, got {x0}`)
		assert(math.abs(1 - x1) < 1e-4, `{name}(1) should be near 1, got {x1}`)
	end
end)

test("should be within range", function()
	for name, easingFunction in pairs(easing) do
		for alpha = 0, 1, 0.1 do
			local x = easingFunction(alpha)
			assert(x < 1.5, `{name}({alpha}) should be less than 1.5, got {x}`)
			assert(x > -0.5, `{name}({alpha}) should be greater than -0.5, got {x}`)
		end
	end
end)

return {}
