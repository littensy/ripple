type Listener = (deltaTime: number) -> ()

local listeners: { [number]: Listener } = {}
local connection: RBXScriptConnection?
local counter = 0

local function id(): number
	counter += 1
	return counter
end

local function step(deltaTime: number)
	for _, listener in listeners do
		listener(deltaTime)
	end
end

local function connect(id: number, listener: Listener)
	listeners[id] = listener

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

local function disconnect(id: number)
	listeners[id] = nil
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
	id = id,
	step = step,
	connect = connect,
	disconnect = disconnect,
	count = count,
	clear = clear,
}
