local types = require("./types")

type MotionState<Value = any> = types.MotionState<Value>

local currentMotions: { [MotionState]: true? } = {}
local pendingMotions: { [MotionState]: true? } = {}
local connection: RBXScriptConnection?

local function ensureCanMutate()
	if currentMotions == pendingMotions then
		pendingMotions = table.clone(currentMotions)
	end
end

local function remove(state: MotionState)
	ensureCanMutate()
	pendingMotions[state] = nil
end

local function update<Value>(state: MotionState<Value>, deltaTime: number): Value
	if state.complete then
		remove(state)
		return state.current:getPosition()
	end

	local position = state.current:step(deltaTime)

	if state.current:idle() then
		remove(state)
		state.complete = true
		state.fireComplete(position)
	end

	return position
end

local function step(deltaTime: number)
	currentMotions = pendingMotions
	for state in currentMotions do
		update(state, deltaTime)
	end
end

local function add(state: MotionState)
	if pendingMotions[state] then
		return
	end

	ensureCanMutate()
	pendingMotions[state] = true

	if not game or connection then
		return
	end

	connection = game:GetService("RunService").Heartbeat:Connect(function(deltaTime)
		debug.profilebegin("RippleMotion")
		step(deltaTime)
		debug.profileend()

		if connection and next(pendingMotions) == nil then
			connection:Disconnect()
			connection = nil
		end
	end)
end

local function clear()
	pendingMotions = {}
	currentMotions = pendingMotions
end

local function get(): { [MotionState]: true? }
	return pendingMotions
end

return {
	update = update,
	step = step,
	add = add,
	remove = remove,
	clear = clear,
	get = get,
}
