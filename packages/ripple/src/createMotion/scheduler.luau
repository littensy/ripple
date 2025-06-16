local types = require("./types")

type MotionState<Value = any> = types.MotionState<Value>

local motions: { MotionState } = {}
local count = 0
local connection: RBXScriptConnection?

local function remove(state: MotionState)
	local index = table.find(motions, state)

	if index then
		motions[index] = motions[count]
		motions[count] = nil
		count -= 1
	end
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
	for index = count, 1, -1 do
		update(motions[index], deltaTime)
	end
end

local function add(state: MotionState)
	if table.find(motions, state) then
		return
	end

	table.insert(motions, state)
	count += 1

	if not game or connection then
		return
	end

	connection = game:GetService("RunService").Heartbeat:Connect(function(deltaTime)
		debug.profilebegin("RippleMotion")
		step(deltaTime)
		debug.profileend()

		if connection and count == 0 then
			connection:Disconnect()
			connection = nil
		end
	end)
end

local function clear()
	table.clear(motions)
	count = 0
end

return {
	motions = motions,
	update = update,
	step = step,
	add = add,
	remove = remove,
	clear = clear,
}
