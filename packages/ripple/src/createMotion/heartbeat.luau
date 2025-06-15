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

local function disconnect(state: MotionState)
	ensureCanMutate()
	pendingMotions[state] = nil
end

local function update<Value>(state: MotionState<Value>, deltaTime: number): Value
	if state.complete then
		disconnect(state)
		return state.current:getPosition()
	end

	local position = state.current:step(deltaTime)

	if state.current:idle() then
		disconnect(state)
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

local function connect(state: MotionState)
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
	table.clear(pendingMotions)
	currentMotions = pendingMotions
end

local function get(): { [MotionState]: true? }
	return pendingMotions
end

return {
	update = update,
	step = step,
	connect = connect,
	disconnect = disconnect,
	clear = clear,
	get = get,
}
