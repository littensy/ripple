local TweenService = game:GetService("TweenService")

local types = require(script.Parent.Parent.types)
local config = require(script.Parent.Parent.config)
local intermediate = require(script.Parent.Parent.utils.intermediate)

local function configure(options: types.TweenOptions?): types.TweenOptions
	if not options then return config.tween.default end

	options = table.clone(options)
	for key, value in config.tween.default do
		options[key] = options[key] or value
	end

	return options
end

local function tween(motionGoal: types.MotionGoal, options: types.TweenOptions?): types.MotionSolver
	local props = configure(options)
	local goals = intermediate.to(motionGoal)

	local progress = 0
	return function(key, state, deltaTime)
		local goal = intermediate.index(goals, key)

		if not goal then
			return false
		end

		local delta = deltaTime * props.speed
		progress = math.clamp(progress + delta, 0, 1)

		local alpha = TweenService:GetValue(progress, props.style, props.direction)
		if progress == 1 then
			state.complete = true
			state.value = goal
		else
			state.value = goal * alpha
		end
	end
end

return tween
