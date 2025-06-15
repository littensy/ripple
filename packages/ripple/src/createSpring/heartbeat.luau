local intermediate = require("../utils/intermediate")
local types = require("./types")

type SpringState<Value = any> = types.SpringState<Value>

local getValue = intermediate.getValue
local recomputeValue = intermediate.recomputeValue

local currentSprings: { [SpringState]: true? } = {}
local pendingSprings: { [SpringState]: true? } = {}
local connection: RBXScriptConnection?

local function ensureCanMutate()
	if currentSprings == pendingSprings then
		pendingSprings = table.clone(currentSprings)
	end
end

local function disconnect(state: SpringState)
	ensureCanMutate()
	pendingSprings[state] = nil
end

local function belowThreshold(value: number | vector, threshold: number): boolean
	if type(value) == "number" then
		return math.abs(value) <= threshold
	else
		local abs = vector.abs(value)
		return math.max(abs.x, abs.y, abs.z) <= threshold
	end
end

local function update<Value>(state: SpringState<Value>, dt: number): Value
	if state.complete then
		disconnect(state)
		return getValue(state.position)
	end

	local position = state.position
	local velocity = state.velocity
	local goal = state.goal
	local restPosition = state.restPosition
	local restVelocity = state.restVelocity
	local d = state.dampingRatio
	local f = state.frequency * 2 * math.pi
	local decay = math.exp(-dt * d * f)
	local complete = true

	local positionComponents = position.components :: { vector }
	local velocityComponents = velocity.components :: { vector }
	local goalComponents = goal.components :: { vector }

	-- Spring calculation from Otter:
	-- https://github.com/Roblox/otter/blob/main/modules/otter/src/spring.lua
	if d == 1 then -- Critically damped
		for key, p0 in positionComponents do
			local v0 = velocityComponents[key]
			local target = goalComponents[key]
			local offset = p0 - target

			local p1 = (v0 * dt + offset * (f * dt + 1)) * decay + target
			local v1 = (v0 - f * dt * (offset * f + v0)) * decay

			if complete then
				complete = belowThreshold(p1 - target, restPosition) and belowThreshold(v1, restVelocity)
			end

			positionComponents[key] = p1
			velocityComponents[key] = v1
		end
	elseif d < 1 then -- Underdamped
		local c = (1 - d * d) ^ 0.5

		local i = math.cos(f * c * dt)
		local j = math.sin(f * c * dt)

		local z
		if c > 1e-4 then
			z = j / c
		else
			local a = dt * f
			z = a + ((a * a) * (c * c) * (c * c) / 20 - c * c) * (a * a * a) / 6
		end

		local y
		if f * c > 1e-4 then
			y = j / (f * c)
		else
			local b = f * c
			y = dt + ((dt * dt) * (b * b) * (b * b) / 20 - b * b) * (dt * dt * dt) / 6
		end

		for key, p0 in positionComponents do
			local v0 = velocityComponents[key]
			local target = goalComponents[key]
			local offset = p0 - target

			local p1 = (offset * (i + d * z) + v0 * y) * decay + target
			local v1 = (v0 * (i - z * d) - offset * (z * f)) * decay

			if complete then
				complete = belowThreshold(p1 - target, restPosition) and belowThreshold(v1, restVelocity)
			end

			positionComponents[key] = p1
			velocityComponents[key] = v1
		end
	else -- Overdamped
		local c = math.sqrt(d * d - 1)

		local r1 = -f * (d - c)
		local r2 = -f * (d + c)

		local ec1 = math.exp(r1 * dt)
		local ec2 = math.exp(r2 * dt)

		for key, p0 in positionComponents do
			local v0 = velocityComponents[key]
			local target = goalComponents[key]
			local offset = p0 - target

			local co2 = (v0 - offset * r1) / (2 * f * c)
			local co1 = ec1 * (offset - co2)

			local p1 = co1 + co2 * ec2 + target
			local v1 = co1 * r1 + co2 * ec2 * r2

			if complete then
				complete = belowThreshold(p1 - target, restPosition) and belowThreshold(v1, restVelocity)
			end

			positionComponents[key] = p1
			velocityComponents[key] = v1
		end
	end

	local value = if not complete then recomputeValue(position) else getValue(goal)

	velocity.dirty = true

	state.complete = complete
	state.fireChange(value, dt)

	if complete then
		disconnect(state)
		intermediate.assign(position, goal)
		intermediate.zero(velocity)
		state.fireComplete(value)
	end

	return value
end

local function step(deltaTime: number)
	currentSprings = pendingSprings
	for state in currentSprings do
		update(state, deltaTime)
	end
end

local function connect(state: SpringState)
	if pendingSprings[state] then
		return
	end

	ensureCanMutate()
	pendingSprings[state] = true

	if not game or connection then
		return
	end

	connection = game:GetService("RunService").Heartbeat:Connect(function(deltaTime)
		debug.profilebegin("RippleSpring")
		step(deltaTime)
		debug.profileend()

		if connection and next(pendingSprings) == nil then
			connection:Disconnect()
			connection = nil
		end
	end)
end

local function clear()
	table.clear(pendingSprings)
	currentSprings = pendingSprings
end

local function get(): { [SpringState]: true? }
	return pendingSprings
end

return {
	update = update,
	step = step,
	connect = connect,
	disconnect = disconnect,
	clear = clear,
	get = get,
}
