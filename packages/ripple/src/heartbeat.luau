type Listener = {
	step: (self: Listener, deltaTime: number) -> (),
}

local listeners: { [Listener]: true } = {}
local connection: RBXScriptConnection?

local function step(deltaTime: number)
	for listener in listeners do
		listener:step(deltaTime)
	end
end

local function disconnect(listener: Listener)
	listeners[listener] = nil

	if connection and not next(listeners) then
		connection:Disconnect()
		connection = nil
	end
end

local function connect(listener: Listener)
	listeners[listener] = true

	if game and not connection then
		connection = game:GetService("RunService").Heartbeat:Connect(function(deltaTime)
			debug.profilebegin("rippleStep")
			step(deltaTime)
			debug.profileend()
		end)
	end
end

local function count(): number
	local count = 0
	for _ in listeners do
		count += 1
	end
	return count
end

local function clear()
	table.clear(listeners)

	if connection then
		connection:Disconnect()
		connection = nil
	end
end

return {
	listeners = listeners,
	step = step,
	connect = connect,
	disconnect = disconnect,
	count = count,
	clear = clear,
}
