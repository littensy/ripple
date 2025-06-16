local motionScheduler = require("../../createMotion/scheduler")
local springScheduler = require("../../createSpring/scheduler")
local tweenScheduler = require("../../createTween/scheduler")

local function countAnimations(): number
	local total = 0
	for _ in motionScheduler.get() do
		total += 1
	end
	for _ in springScheduler.get() do
		total += 1
	end
	for _ in tweenScheduler.get() do
		total += 1
	end
	return total
end

return countAnimations
