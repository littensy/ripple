local heartbeat = require("../heartbeat")
local intermediate = require("../utils/intermediate")
local signal = require("../utils/signal")
local types = require("../types")

type Animatable = types.Animatable
type Intermediate<T> = intermediate.Intermediate<T>
type Signal<T> = signal.Signal<T>

export type SpringConfig<T = any> = {
	start: boolean?,
	tension: number?,
	friction: number?,
	mass: number?,
	dampingRatio: number?,
	frequency: number?,
	precision: number?,
	restVelocity: number?,
	position: T?,
	velocity: T?,
	impulse: T?,
}

type SpringApi<T = any> = {
	onStep: (callback: (value: T, deltaTime: number) -> ()) -> () -> (),
	onComplete: (callback: (value: T) -> ()) -> () -> (),

	step: (deltaTime: number) -> T,
	to: (goal: T, config: SpringConfig?) -> (),
	impulse: (amount: T) -> (),
	configure: (config: SpringConfig) -> (),

	start: () -> (),
	stop: () -> (),
	destroy: () -> (),
}

export type Spring<T = any> = SpringApi & {
	position: T,
	velocity: T,
	goal: T,
	complete: boolean,
}

local VELOCITY_THRESHOLD_MULTIPLIER = 0.1

--- @see https://github.com/Roblox/otter/blob/main/modules/otter/src/spring.lua
local function computeSpring(
	dt: number,
	p0: number,
	v0: number,
	g: number,
	d: number,
	f: number,
	decay: number
): (number, number)
	local offset = p0 - g
	local p1, v1

	if d == 1 then -- Critically damped
		p1 = (v0 * dt + offset * (f * dt + 1)) * decay + g
		v1 = (v0 - f * dt * (offset * f + v0)) * decay
	elseif d < 1 then -- Underdamped
		local c = math.sqrt(1 - d * d)

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

		p1 = (offset * (i + d * z) + v0 * y) * decay + g
		v1 = (v0 * (i - z * d) - offset * (z * f)) * decay
	else -- Overdamped
		local c = math.sqrt(d * d - 1)

		local r1 = -f * (d - c)
		local r2 = -f * (d + c)

		local co2 = (v0 - r1 * offset) / (2 * f * c)
		local co1 = offset - co2

		local e1 = co1 * math.exp(r1 * dt)
		local e2 = co2 * math.exp(r2 * dt)

		p1 = e1 + e2 + g
		v1 = r1 * e1 + r2 * e2
	end

	return p1, v1
end

local function belowThreshold(value: number | vector, threshold: number): boolean
	if type(value) == "number" then
		return math.abs(value) <= threshold
	else
		local abs = vector.abs(value)
		return math.max(abs.x, abs.y, abs.z) <= threshold
	end
end

local function createSpring<T>(initialValue: T & Animatable, config: SpringConfig<T>?): Spring<T>
	local config: SpringConfig = config or {}

	local position = intermediate.create(config.position or initialValue)
	local velocity = intermediate.zero(intermediate.create(config.impulse or config.velocity or initialValue))
	local goal = intermediate.create(config.position or initialValue)

	local dampingRatio = 1
	local frequency = 1
	local restPosition = 1e-3
	local restVelocity = restPosition * VELOCITY_THRESHOLD_MULTIPLIER

	local onStep = signal()
	local onComplete = signal()

	local id = heartbeat.id()
	local started = config.start or false
	local complete = true

	local function step(dt: number): T
		if complete then
			return intermediate.getValue(position)
		end

		local angularFrequency = frequency * 2 * math.pi
		local decay = math.exp(-dt * dampingRatio * angularFrequency)
		complete = true

		for key, lastPosition in position.components :: { number } do
			local lastVelocity = velocity.components[key] :: number
			local target = goal.components[key] :: number
			local currentPosition, currentVelocity =
				computeSpring(dt, lastPosition, lastVelocity, target, dampingRatio, angularFrequency, decay)

			position.components[key], position.dirty = currentPosition, true
			velocity.components[key], velocity.dirty = currentVelocity, true

			if complete then
				complete = belowThreshold(currentPosition - target, restPosition)
					and belowThreshold(currentVelocity, restVelocity)
			end
		end

		local value = intermediate.getValue(if complete then goal else position)

		onStep.fire(value, dt)

		if complete then
			heartbeat.disconnect(id)
			intermediate.assign(position, goal)
			intermediate.zero(velocity)
			onComplete.fire(value)
		end

		return value
	end

	local function scheduleUpdate()
		complete = false
		if started then
			heartbeat.connect(id, step)
		end
	end

	local function setPosition(value: T)
		intermediate.setValue(position, value)
		scheduleUpdate()
	end

	local function setVelocity(value: T)
		intermediate.setValue(velocity, value)
		scheduleUpdate()
	end

	local function setGoal(value: T)
		intermediate.setValue(goal, value)
		scheduleUpdate()
	end

	local function impulse(value: T)
		intermediate.addValue(velocity, value)
		scheduleUpdate()
	end

	local function configure(config: SpringConfig)
		restPosition = config.precision or restPosition
		restVelocity = config.restVelocity or restPosition * VELOCITY_THRESHOLD_MULTIPLIER

		if config.friction or config.tension or config.mass then
			local tension = config.tension or 170
			local friction = config.friction or 26
			local mass = config.mass or 1

			dampingRatio = friction / (2 * (mass * tension) ^ 0.5)
			frequency = (tension / mass) ^ 0.5 / 2 / math.pi
		else
			dampingRatio = config.dampingRatio or dampingRatio
			frequency = config.frequency or frequency
		end

		if config.position then
			setPosition(config.position)
		end

		if config.velocity then
			setVelocity(config.velocity)
		end

		if config.impulse then
			impulse(config.impulse)
		end
	end

	local function to(value: T, config: SpringConfig?)
		if config then
			configure(config)
		end
		setGoal(value)
	end

	local function stop()
		started = false
		heartbeat.disconnect(id)
	end

	local function start()
		started = true
		if not complete then
			heartbeat.connect(id, step)
		end
	end

	local function getter(_, key: any): any
		if key == "position" then
			return intermediate.getValue(position)
		elseif key == "velocity" then
			return intermediate.getValue(velocity)
		elseif key == "goal" then
			return intermediate.getValue(goal)
		elseif key == "complete" then
			return complete
		else
			return nil
		end
	end

	local function setter(self: any, key: any, value: any)
		if key == "position" then
			setPosition(value)
		elseif key == "velocity" then
			setVelocity(value)
		elseif key == "goal" then
			setGoal(value)
		elseif key == "complete" then
			warn("Cannot set 'complete' property directly. Use 'stop()' to stop the spring.")
		else
			rawset(self, key, value)
		end
	end

	local spring: SpringApi<T> = {
		onStep = onStep.connect,
		onComplete = onComplete.connect,
		step = step,
		to = to,
		impulse = impulse,
		configure = configure,
		start = start,
		stop = stop,
		destroy = stop,
	}

	configure(config)

	if config.start then
		start()
	end

	return setmetatable(spring, {
		__index = getter,
		__newindex = setter,
	}) :: any
end

return createSpring
