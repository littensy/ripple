local motionHeartbeat = require("../../createMotion/heartbeat")
local springHeartbeat = require("../../createSpring/heartbeat")
local tweenHeartbeat = require("../../createTween/heartbeat")

local function countAnimations(): number
	local total = 0
	for _ in motionHeartbeat.get() do
		total += 1
	end
	for _ in springHeartbeat.get() do
		total += 1
	end
	for _ in tweenHeartbeat.get() do
		total += 1
	end
	return total
end

return countAnimations
