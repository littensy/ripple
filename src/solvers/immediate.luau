local types = require(script.Parent.Parent.types)
local intermediate = require(script.Parent.Parent.utils.intermediate)

local function immediate(motionGoal: types.MotionGoal): types.MotionSolver
	local goals = intermediate.to(motionGoal)

	return function(key, state, deltaTime)
		local goal = intermediate.index(goals, key)

		if not goal then
			return false
		end

		if deltaTime > 0 then
			state.value = goal
			state.complete = true
		end
	end
end

return immediate
