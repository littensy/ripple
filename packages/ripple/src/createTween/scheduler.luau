local interpolate = require("../utils/interpolate")
local types = require("./types")

type TweenState<Value = any> = types.TweenState<Value>

local tweens: { TweenState } = {}
local count = 0
local connection: RBXScriptConnection?

local function remove(state: TweenState)
	local index = table.find(tweens, state)

	if index then
		tweens[index] = tweens[count]
		tweens[count] = nil
		count -= 1
	end
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
	for index = count, 1, -1 do
		update(tweens[index], deltaTime)
	end
end

local function add(state: TweenState)
	if table.find(tweens, state) then
		return
	end

	table.insert(tweens, state)
	count += 1

	if not game or connection then
		return
	end

	connection = game:GetService("RunService").Heartbeat:Connect(function(deltaTime)
		debug.profilebegin("RippleTween")
		step(deltaTime)
		debug.profileend()

		if connection and count == 0 then
			connection:Disconnect()
			connection = nil
		end
	end)
end

local function clear()
	table.clear(tweens)
	count = 0
end

return {
	tweens = tweens,
	update = update,
	step = step,
	add = add,
	remove = remove,
	clear = clear,
}
