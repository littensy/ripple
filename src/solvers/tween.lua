local TweenService = game:GetService("TweenService")

local types = require(script.Parent.Parent.types)
local intermediate = require(script.Parent.Parent.utils.intermediate)
local merge = require(script.Parent.Parent.utils.merge)

local defaults = {
	time = 1,
	style = Enum.EasingStyle.Quad,
	direction = Enum.EasingDirection.Out,
	repeatCount = 0,
	reverses = false,
	delayTime = 0,
}

local function createTween(from: number, to: number, options: types.TweenOptions): (NumberValue, Tween)
	local tweenInfo = TweenInfo.new(
		options.time,
		options.style,
		options.direction,
		options.repeatCount,
		options.reverses,
		options.delayTime
	)

	local value = Instance.new("NumberValue")
	local tween = TweenService:Create(value, tweenInfo, { Value = to })

	value.Value = from

	return value, tween
end

local function tween(motionGoal: types.MotionGoal, options: types.TweenOptions?): types.MotionSolver
	local config = merge(defaults, options or {})
	local goals = intermediate.to(motionGoal)

	local complete = false
	local value, tweenInstance

	return function(key, state)
		local goal = intermediate.index(goals, key)

		if not goal then
			return false
		end

		if not state.destructor then
			-- todo: this should update on step instead of running in the background
			value, tweenInstance = createTween(state.value, goal, config)

			tweenInstance.Completed:Connect(function()
				complete = true
				value:Destroy()
				tweenInstance:Destroy()
			end)

			tweenInstance:Play()

			function state.destructor()
				tweenInstance:Destroy()
				value:Destroy()
			end
		end

		if complete then
			state.complete = true
			state.value = goal
		else
			state.value = value.Value
		end
	end
end

return tween
