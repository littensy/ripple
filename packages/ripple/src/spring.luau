local intermediate = require("./utils/intermediate")
local schedule = require("./utils/schedule")
local signal = require("./utils/signal")
local types = require("./types")

type Animatable = types.Animatable
type Intermediate<Value> = intermediate.Intermediate<Value>

local getValue = intermediate.getValue
local recomputeValue = intermediate.recomputeValue

export type SpringState<Value = any> = {
	position: intermediate.Intermediate<Value>,
	velocity: intermediate.Intermediate<Value>,
	goal: intermediate.Intermediate<Value>,
	dampingRatio: number,
	frequency: number,
	restPosition: number,
	restVelocity: number,
	started: boolean,
	complete: boolean,
	onChange: signal.SubscribeSignal<(Value, number)>,
	fireChange: signal.FireSignal<(Value, number)>,
	onComplete: signal.SubscribeSignal<Value>,
	fireComplete: signal.FireSignal<Value>,
}

export type SpringOptions<Value = any> = {
	start: boolean?,
	tension: number?,
	friction: number?,
	mass: number?,
	dampingRatio: number?,
	frequency: number?,
	precision: number?,
	restVelocity: number?,
	position: Value?,
	velocity: Value?,
	impulse: Value?,
}

export type Spring<Value = any> = {
	state: SpringState<Value>,

	setPosition: (self: Spring<Value>, value: Value) -> (),
	setVelocity: (self: Spring<Value>, value: Value) -> (),
	setGoal: (self: Spring<Value>, value: Value, options: SpringOptions<Value>?) -> (),

	getPosition: (self: Spring<Value>) -> Value,
	getVelocity: (self: Spring<Value>) -> Value,
	getGoal: (self: Spring<Value>) -> Value,

	onChange: (self: Spring<Value>, callback: (value: Value, deltaTime: number) -> ()) -> () -> (),
	onComplete: (self: Spring<Value>, callback: (value: Value) -> ()) -> () -> (),

	step: (self: Spring<Value>, deltaTime: number) -> Value,
	impulse: (self: Spring<Value>, amount: Value) -> (),
	halt: (self: Spring<Value>) -> (),
	idle: (self: Spring<Value>) -> boolean,
	configure: (self: Spring<Value>, options: SpringOptions<Value>) -> (),

	start: (self: Spring<Value>) -> (),
	stop: (self: Spring<Value>) -> (),
	destroy: (self: Spring<Value>) -> (),

	scheduleUpdate: (self: Spring<Value>) -> (),
}

local DEFAULT_REST_POSITION = 1e-3
local VELOCITY_THRESHOLD_MULTIPLIER = 1000 / 16

local Spring = {} :: Spring<Animatable>
(Spring :: any).__index = Spring

local function belowThreshold(value: number | vector, threshold: number): boolean
	if type(value) == "number" then
		return math.abs(value) <= threshold
	else
		local abs = vector.abs(value)
		return math.max(abs.x, abs.y, abs.z) <= threshold
	end
end

local scheduler = schedule("Spring", function<T>(state: SpringState<T>, dt, remove): T
	if state.complete then
		remove(state)
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
		remove(state)
		intermediate.assign(position, goal)
		intermediate.zero(velocity)
		state.fireComplete(value)
	end

	return value
end)

local function createSpring<Value>(initialValue: Value, inputOptions: SpringOptions<Value>?): Spring<Value>
	local options: SpringOptions<Value> = inputOptions or {}
	local position = intermediate.create(options.position or initialValue)

	local onChange, fireChange = signal()
	local onComplete, fireComplete = signal()

	local state: SpringState<Value> = {
		position = position,
		velocity = intermediate.zero(intermediate.copy(position)),
		goal = intermediate.copy(position),
		dampingRatio = 1,
		frequency = 1,
		restPosition = DEFAULT_REST_POSITION,
		restVelocity = DEFAULT_REST_POSITION * VELOCITY_THRESHOLD_MULTIPLIER,
		started = false,
		complete = true,
		onChange = onChange,
		fireChange = fireChange,
		onComplete = onComplete,
		fireComplete = fireComplete,
	}

	local self: Spring<Value> = setmetatable({
		state = state,
	}, Spring) :: any

	self:configure(options)

	if options.start then
		self:start()
	end

	return self
end

function Spring:scheduleUpdate()
	self.state.complete = false

	if self.state.started then
		scheduler.add(self.state)
	end
end

function Spring:start()
	self.state.started = true

	if not self.state.complete then
		scheduler.add(self.state)
	end
end

function Spring:stop()
	self.state.started = false
	scheduler.remove(self.state)
end

function Spring:idle(): boolean
	return self.state.complete
end

function Spring:step(dt: number): Animatable
	return scheduler.update(self.state, dt)
end

function Spring:configure(options: SpringOptions)
	local state = self.state

	state.restPosition = options.precision or state.restPosition
	state.restVelocity = options.restVelocity or state.restPosition * VELOCITY_THRESHOLD_MULTIPLIER

	if options.dampingRatio or options.frequency then
		state.dampingRatio = options.dampingRatio or state.dampingRatio
		state.frequency = options.frequency or state.frequency
	else
		local tension = options.tension or 170
		local friction = options.friction or 26
		local mass = options.mass or 1

		state.dampingRatio = friction / (2 * (mass * tension) ^ 0.5)
		state.frequency = (tension / mass) ^ 0.5 / 2 / math.pi
	end

	if options.velocity then
		self:setVelocity(options.velocity)
	end

	if options.impulse then
		self:impulse(options.impulse)
	end

	if options.position then
		self:setPosition(options.position)
	end
end

function Spring:getPosition(): Animatable
	return intermediate.getValue(self.state.position)
end

function Spring:getVelocity(): Animatable
	return intermediate.getValue(self.state.velocity)
end

function Spring:getGoal(): Animatable
	return intermediate.getValue(self.state.goal)
end

function Spring:setPosition(value: Animatable)
	if intermediate.setValue(self.state.position, value) then
		self:scheduleUpdate()
		self.state.fireChange(intermediate.getValue(self.state.position), 0)
	end
end

function Spring:setVelocity(value: Animatable)
	if intermediate.setValue(self.state.velocity, value) then
		self:scheduleUpdate()
	end
end

function Spring:setGoal(value: Animatable, options: SpringOptions?)
	if options then
		self:configure(options)
	end

	if intermediate.setValue(self.state.goal, value) then
		self:scheduleUpdate()
	end
end

function Spring:impulse(value: Animatable)
	intermediate.addValue(self.state.velocity, value)
	self:scheduleUpdate()
end

function Spring:halt()
	intermediate.zero(self.state.velocity)
end

function Spring:onChange(callback: (value: Animatable, deltaTime: number) -> ()): () -> ()
	return self.state.onChange(callback)
end

function Spring:onComplete(callback: (value: Animatable) -> ()): () -> ()
	return self.state.onComplete(callback)
end

function Spring:destroy()
	self:stop()
end

return {
	scheduler = scheduler,
	createSpring = createSpring,
}
