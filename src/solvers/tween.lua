local TweenService = game:GetService("TweenService")

local types = require(script.Parent.Parent.types)
local config = require(script.Parent.Parent.config)
local intermediate = require(script.Parent.Parent.utils.intermediate)
local merge = require(script.Parent.Parent.utils.merge)

type TweenEntry = {
	value: NumberValue,
	tween: Tween,
	complete: boolean,
}

local function createTween(from: number, to: number, options: types.TweenOptions): TweenEntry
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

	return {
		value = value,
		tween = tween,
		complete = false,
	}
end

local function tween(motionGoal: types.MotionGoal, options: types.TweenOptions?): types.MotionSolver
	local props = merge(config.tween.default, options or {})
	local goals = intermediate.to(motionGoal)
	local entries: { [unknown]: TweenEntry? } = {}

	return function(key, state)
		local goal = intermediate.index(goals, key)

		if not goal then
			return false
		end

		if not state.destructor then
			local entry = createTween(state.value, goal, props)

			entries[key] = entry

			entry.tween.Completed:Connect(function()
				entry.complete = true
				entry.value:Destroy()
				entry.tween:Destroy()
			end)

			entry.tween:Play()

			function state.destructor()
				entry.tween:Destroy()
				entry.value:Destroy()
				entries[key] = nil
			end
		end

		local entry = entries[key]

		if not entry then
			state.complete = true
		elseif entry.complete then
			state.complete = true
			state.value = goal
		else
			state.value = entry.value.Value
		end
	end
end

return tween
