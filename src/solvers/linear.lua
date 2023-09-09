local types = require(script.Parent.Parent.types)
local config = require(script.Parent.Parent.config)
local intermediate = require(script.Parent.Parent.utils.intermediate)

local function configure(options: types.LinearOptions)
	local speed = if type(options) == "table" then options.speed else options

	return {
		speed = speed or config.linear.default.speed,
	}
end

local function linear(motionGoal: types.MotionGoal, options: types.LinearOptions): types.MotionSolver
	local props = configure(options)
	local goals = intermediate.to(motionGoal)

	return function(key, state, deltaTime)
		local goal = intermediate.index(goals, key)

		if not goal then
			return false
		end

		local velocity = props.speed * deltaTime * math.sign(goal - state.value)

		if math.abs(velocity) >= math.abs(goal - state.value) then
			state.complete = true
			state.value = goal
			state.velocity = 0
		else
			state.value += velocity
			state.velocity = velocity
		end
	end
end

return linear
