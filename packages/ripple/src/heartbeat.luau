type Listener = (deltaTime: number) -> ()

local currentListeners: { Listener } = {}
local nextListeners: { Listener } = currentListeners
local nextListenerId = 0
local connection: RBXScriptConnection?

local function id(): number
	nextListenerId += 1
	return nextListenerId
end

local function ensureCanMutateNextListeners()
	if nextListeners == currentListeners then
		nextListeners = table.clone(currentListeners)
	end
end

local function step(deltaTime: number)
	currentListeners = nextListeners

	for _, listener in currentListeners do
		listener(deltaTime)
	end
end

local function connectToHeartbeat()
	if not game or connection then
		return
	end

	connection = game:GetService("RunService").Heartbeat:Connect(function(deltaTime)
		debug.profilebegin("rippleStep")
		step(deltaTime)
		debug.profileend()

		if connection and not next(nextListeners) then
			connection:Disconnect()
			connection = nil
		end
	end)
end

local function connect(id: number, listener: Listener)
	if nextListeners[id] ~= listener then
		connectToHeartbeat()
		ensureCanMutateNextListeners()
		nextListeners[id] = listener
	end
end

local function disconnect(id: number)
	if nextListeners[id] then
		ensureCanMutateNextListeners()
		nextListeners[id] = nil
	end
end

local function count(): number
	local count = 0
	for _ in nextListeners do
		count += 1
	end
	return count
end

local function clear()
	table.clear(nextListeners)
	currentListeners = nextListeners
end

return {
	id = id,
	step = step,
	connect = connect,
	disconnect = disconnect,
	count = count,
	clear = clear,
}
