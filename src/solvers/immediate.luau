local types = require(script.Parent.Parent.types)
local intermediate = require(script.Parent.Parent.utils.intermediate)

local function immediate(motionGoal: types.MotionGoal): types.MotionSolver
	local goals = intermediate.to(motionGoal)

	return function(key, state)
		local goal = intermediate.index(goals, key)

		if not goal then
			return false
		end

		state.complete = true
		state.value = goal
	end
end

return immediate
