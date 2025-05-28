type Listener = {
	step: (self: Listener, deltaTime: number) -> (),
}

local currentListeners: { [Listener]: true? } = {}
local nextListeners: { [Listener]: true? } = currentListeners
local connection: RBXScriptConnection?

local function ensureCanMutateNextListeners()
	if nextListeners == currentListeners then
		nextListeners = table.clone(currentListeners)
	end
end

local function step(deltaTime: number)
	currentListeners = nextListeners

	for listener in currentListeners do
		listener:step(deltaTime)
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

local function connect(listener: Listener)
	if not nextListeners[listener] then
		connectToHeartbeat()
		ensureCanMutateNextListeners()
		nextListeners[listener] = true
	end
end

local function disconnect(listener: Listener)
	if nextListeners[listener] then
		ensureCanMutateNextListeners()
		nextListeners[listener] = nil
	end
end

local function count(): number
	local listenerCount = 0
	for _ in nextListeners do
		listenerCount += 1
	end
	return listenerCount
end

local function clear()
	table.clear(nextListeners)
	currentListeners = nextListeners
end

return {
	step = step,
	connect = connect,
	disconnect = disconnect,
	count = count,
	clear = clear,
}
