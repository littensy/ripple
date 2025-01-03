local RunService = game:GetService("RunService")

type OnHeartbeat = (deltaTime: number) -> ()

local connection: RBXScriptConnection?
local listeners: { [OnHeartbeat]: true } = {}

local function step(deltaTime: number)
	debug.profilebegin("RIPPLE")
	for listener in listeners do
		listener(deltaTime)
	end
	debug.profileend()
end

local function disconnect(callback: OnHeartbeat)
	listeners[callback] = nil

	if connection and not next(listeners) then
		connection:Disconnect()
		connection = nil
	end
end

local function connect(callback: OnHeartbeat)
	listeners[callback] = true

	if not connection then
		connection = RunService.Heartbeat:Connect(step)
	end
end

return {
	connect = connect,
	disconnect = disconnect,
}
