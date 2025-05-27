local heartbeat = require("../heartbeat")
local intermediate = require("../utils/intermediate")
local signal = require("../utils/signal")

type Intermediate<T> = intermediate.Intermediate<T>
type FireSignal<T...> = signal.FireSignal<T...>
type SubscribeSignal<T...> = signal.SubscribeSignal<T...>

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

type SpringApi<T> = {
	onChange: (callback: (value: T, deltaTime: number) -> ()) -> () -> (),
	onComplete: (callback: (value: T) -> ()) -> () -> (),

	step: (deltaTime: number) -> T,
	to: (goal: T, config: SpringConfig<T>?) -> (),
	impulse: (amount: T) -> (),
	halt: () -> (),
	idle: () -> boolean,
	configure: (config: SpringConfig<T>) -> (),

	start: () -> (),
	stop: () -> (),
	destroy: () -> (),
}

export type Spring<T = any> = SpringApi<T> & {
	position: T,
	velocity: T,
	goal: T,
}

local VELOCITY_THRESHOLD_MULTIPLIER = 1000 / 16

local function belowThreshold(value: number | vector, threshold: number): boolean
	if type(value) == "number" then
		return math.abs(value) <= threshold
	else
		local max = vector.create(threshold, threshold, threshold)
		return vector.max(vector.abs(value), max) == max
	end
end

local function createSpring<T>(initialValue: T, config: SpringConfig<T>?): Spring<T>
	local config: SpringConfig<T> = config or {}

	local position = intermediate.create(config.position or initialValue)
	local velocity = intermediate.zero(intermediate.create(config.impulse or config.velocity or initialValue))
	local goal = intermediate.create(config.position or initialValue)

	local dampingRatio = 1
	local frequency = 1
	local restPosition = 1e-3
	local restVelocity = restPosition * VELOCITY_THRESHOLD_MULTIPLIER

	local id = heartbeat.id()
	local started = false
	local complete = true

	local onChange: SubscribeSignal<(T, number)>, fireChange: FireSignal<(T, number)> = signal()
	local onComplete: SubscribeSignal<T>, fireComplete: FireSignal<T> = signal()

	local function step(dt: number): T
		if complete then
			return intermediate.getValue(position)
		end

		local d = dampingRatio
		local f = frequency * 2 * math.pi
		local decay = math.exp(-dt * dampingRatio * f)

		complete = true

		for key, p0 in position.components :: { number } do
			local v0 = velocity.components[key] :: number
			local g = goal.components[key] :: number

			local offset = p0 - g
			local p1, v1

			-- Spring calculation from Otter:
			-- https://github.com/Roblox/otter/blob/main/modules/otter/src/spring.lua
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

			if complete then
				if belowThreshold(p1 - g, restPosition) and belowThreshold(v1, restVelocity) then
					p1 = g
					v1 *= 0
				else
					complete = false
				end
			end

			position.components[key], position.dirty = p1, true
			velocity.components[key], velocity.dirty = v1, true
		end

		local value = intermediate.getValue(if complete then goal else position)

		fireChange(value, dt)

		if complete then
			heartbeat.disconnect(id)
			intermediate.assign(position, goal)
			intermediate.zero(velocity)
			fireComplete(value)
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
		if intermediate.setValue(position, value) then
			scheduleUpdate()
			fireChange(value, 0)
		end
	end

	local function setVelocity(value: T)
		if intermediate.setValue(velocity, value) then
			scheduleUpdate()
		end
	end

	local function setGoal(value: T)
		if intermediate.setValue(goal, value) then
			scheduleUpdate()
		end
	end

	local function impulse(value: T)
		intermediate.addValue(velocity, value)
		scheduleUpdate()
	end

	local function halt()
		intermediate.zero(velocity)
	end

	local function idle(): boolean
		return complete
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

	local function configure(config: SpringConfig<T>)
		restPosition = config.precision or restPosition
		restVelocity = config.restVelocity or restPosition * VELOCITY_THRESHOLD_MULTIPLIER

		if config.dampingRatio or config.frequency then
			dampingRatio = config.dampingRatio or dampingRatio
			frequency = config.frequency or frequency
		else
			local tension = config.tension or 170
			local friction = config.friction or 26
			local mass = config.mass or 1

			dampingRatio = friction / (2 * (mass * tension) ^ 0.5)
			frequency = (tension / mass) ^ 0.5 / 2 / math.pi
		end

		if config.velocity then
			setVelocity(config.velocity)
		end

		if config.impulse then
			impulse(config.impulse)
		end

		if config.position then
			setPosition(config.position)
		end
	end

	local function to(value: T, config: SpringConfig<T>?)
		if config then
			configure(config)
		end
		setGoal(value)
	end

	local function getter(_, key: any): any
		if key == "position" then
			return intermediate.getValue(position)
		elseif key == "velocity" then
			return intermediate.getValue(velocity)
		elseif key == "goal" then
			return intermediate.getValue(goal)
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
		else
			rawset(self, key, value)
		end
	end

	local spring: SpringApi<T> = {
		onChange = onChange,
		onComplete = onComplete,
		step = step,
		to = to,
		impulse = impulse,
		halt = halt,
		configure = configure,
		idle = idle,
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
