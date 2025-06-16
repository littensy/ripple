local interpolate = require("../utils/interpolate")
local types = require("./types")

type TweenState<Value = any> = types.TweenState<Value>

local currentTweens: { [TweenState]: true? } = {}
local pendingTweens: { [TweenState]: true? } = {}
local connection: RBXScriptConnection?

local function ensureCanMutate()
	if currentTweens == pendingTweens then
		pendingTweens = table.clone(currentTweens)
	end
end

local function remove(state: TweenState)
	ensureCanMutate()
	pendingTweens[state] = nil
end

local function getAlpha(progress: number, repeats: number, reverses: boolean): number
	if repeats > 1 and progress >= 1 then
		if reverses then
			return math.abs((progress - 1) % 2 - 1)
		elseif progress < repeats then
			return progress % 1
		end
		return 1
	end
	return progress
end

local function update<Value>(state: TweenState<Value>, dt: number): Value
	if state.complete then
		remove(state)
		return state.position
	end

	state.elapsed += dt

	local progress = math.clamp(state.elapsed / state.duration, 0, state.repeats)
	local alpha = getAlpha(progress, state.repeats, state.reverses)
	local alphaEased = if alpha > 0 and alpha < 1 then state.easingFunction(alpha) else alpha
	local value = interpolate(state.from, state.goal, alphaEased)

	state.position = value
	state.fireChange(value, dt)

	if progress == state.repeats then
		remove(state)
		state.complete = true
		state.fireComplete(value)
	end

	return value
end

local function step(deltaTime: number)
	currentTweens = pendingTweens
	for state in currentTweens do
		update(state, deltaTime)
	end
end

local function add(state: TweenState)
	if pendingTweens[state] then
		return
	end

	ensureCanMutate()
	pendingTweens[state] = true

	if connection or not game then
		return
	end

	connection = game:GetService("RunService").Heartbeat:Connect(function(deltaTime)
		debug.profilebegin("RippleTween")
		step(deltaTime)
		debug.profileend()

		if connection and next(pendingTweens) == nil then
			connection:Disconnect()
			connection = nil
		end
	end)
end

local function clear()
	pendingTweens = {}
	currentTweens = pendingTweens
end

local function get(): { [TweenState]: true? }
	return pendingTweens
end

return {
	update = update,
	step = step,
	add = add,
	remove = remove,
	clear = clear,
	get = get,
}
