type Listener = {
	step: (self: Listener, deltaTime: number, elapsed: number) -> (),
}

local listeners: { [Listener]: number } = {}
local connection: RBXScriptConnection?

local function step(deltaTime: number)
	local now = os.clock()
	for listener, start in listeners do
		listener:step(deltaTime, now - start)
	end
end

local function connect(listener: Listener)
	listeners[listener] = os.clock()

	if game and not connection then
		connection = game:GetService("RunService").Heartbeat:Connect(function(deltaTime)
			debug.profilebegin("rippleStep")
			step(deltaTime)
			debug.profileend()

			if connection and not next(listeners) then
				connection:Disconnect()
				connection = nil
			end
		end)
	end
end

local function disconnect(listener: Listener)
	listeners[listener] = nil
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
end

return {
	listeners = listeners,
	step = step,
	connect = connect,
	disconnect = disconnect,
	count = count,
	clear = clear,
}
