local fuzzyEqual = require("../utils/fuzzyEqual")
local heartbeat = require("../heartbeat")
local intermediate = require("../utils/intermediate")
local signal = require("../utils/signal")
local types = require("../types")

type Animatable = types.Animatable
type Intermediate<T> = intermediate.Intermediate<T>
type Signal<T> = signal.Signal<T>

export type SpringConfig<T = any> = {
	start: boolean?,
	mass: number?,
	tension: number?,
	friction: number?,
	frequency: number?,
	damping: number?,
	precision: number?,
	restVelocity: number?,
	position: T?,
	velocity: T?,
	impulse: T?,
}

export type SpringState<T = any> = {
	position: Intermediate<T>,
	velocity: Intermediate<T>,
	goal: Intermediate<T>,

	mass: number,
	tension: number,
	friction: number,
	restPosition: number,
	restVelocity: number,

	started: boolean,
	complete: boolean,

	onStep: Signal<(value: T, deltaTime: number) -> ()>,
	onComplete: Signal<(value: T) -> ()>,
}

type SpringApi<T = any, U = any> = {
	onStep: (self: U, callback: (value: T, deltaTime: number) -> ()) -> () -> (),
	onComplete: (self: U, callback: (value: T) -> ()) -> () -> (),

	step: (self: U, deltaTime: number) -> T,
	to: (self: U, goal: T, config: SpringConfig<T>?) -> (),
	impulse: (self: U, amount: T) -> (),
	configure: (self: U, config: SpringConfig<T>) -> (),

	start: (self: U) -> (),
	stop: (self: U) -> (),
	destroy: (self: U) -> (),
}

type SpringInternal<T = any> = SpringApi<T, SpringInternal<T>> & {
	__state: SpringState<T>,
}

export type Spring<T = any> = SpringApi<T, Spring<T>> & {
	position: T,
	velocity: T,
	goal: T,
	complete: boolean,
}

local UPDATE_RATE = 1000
local STEP = 1 / UPDATE_RATE

local Spring = {} :: SpringInternal

local function createSpring<T>(initialValue: T & Animatable, config: SpringConfig<T>?): Spring<T>
	local config: SpringConfig<T> = config or {}

	local state: SpringState<T> = {
		position = intermediate.create(config.position or initialValue),
		velocity = intermediate.zero(intermediate.create(config.impulse or config.velocity or initialValue)),
		goal = intermediate.create(config.position or initialValue),

		mass = 1,
		tension = 170,
		friction = 26,
		restPosition = 0.001,
		restVelocity = 0.0001,

		started = config.start or false,
		complete = true,

		onStep = signal(),
		onComplete = signal(),
	}

	local self: Spring<T> = setmetatable({
		__state = state,
	}, Spring) :: any

	self:configure(config)

	return self
end

local function scheduleUpdate<T>(self: SpringInternal<T>)
	self.__state.complete = false
	if self.__state.started then
		heartbeat.connect(self)
	end
end

local function setPosition<T>(self: SpringInternal<T>, value: T)
	intermediate.setValue(self.__state.position, value)
	scheduleUpdate(self)
end

local function setVelocity<T>(self: SpringInternal<T>, value: T)
	intermediate.setValue(self.__state.velocity, value)
	scheduleUpdate(self)
end

local function setGoal<T>(self: SpringInternal<T>, value: T)
	intermediate.setValue(self.__state.goal, value)
	scheduleUpdate(self)
end

function Spring.step<T>(self: SpringInternal<T>, deltaTime: number): T
	local state = self.__state

	if state.complete then
		return intermediate.getValue(state.position)
	end

	local position = state.position
	local velocity = state.velocity
	local goal = state.goal

	local mass = state.mass
	local tension = state.tension
	local friction = state.friction
	local restPosition = state.restPosition
	local restVelocity = state.restVelocity

	local passes = math.min(math.ceil(deltaTime * UPDATE_RATE), 500)

	state.complete = true

	for key, pos in position.components :: { number } do
		local vel = velocity.components[key] :: number
		local to = goal.components[key] :: number

		for _ = 1, passes do
			local springForce = -(STEP ^ 2) * tension * (pos - to)
			local dampingForce = -STEP * friction * vel
			local acceleration = (springForce + dampingForce) / mass

			vel += acceleration
			pos += vel
		end

		position.components[key], position.dirty = pos, true
		velocity.components[key], velocity.dirty = vel, true

		if state.complete then
			state.complete = fuzzyEqual(pos, to, restPosition) and fuzzyEqual(vel, vel * 0, restVelocity)
		end
	end

	local value = intermediate.getValue(state.complete and state.goal or state.position)

	state.onStep.fire(value, deltaTime)

	if state.complete then
		heartbeat.disconnect(self)
		intermediate.assign(position, goal)
		intermediate.zero(velocity)
		state.onComplete.fire(value)
	end

	return value
end

function Spring.impulse<T>(self: SpringInternal<T>, value: T)
	intermediate.addValue(self.__state.velocity, value)
	scheduleUpdate(self)
end

function Spring.configure<T>(self: SpringInternal<T>, config: SpringConfig<T>)
	local state = self.__state

	state.mass = config.mass or state.mass
	state.restPosition = config.precision or state.restPosition
	state.restVelocity = config.restVelocity or state.restPosition / 10

	if config.damping or config.frequency then
		local frequency = config.frequency or 0.5
		local damping = config.damping or 1

		state.tension = (2 * math.pi / frequency) ^ 2 * state.mass
		state.friction = (4 * math.pi * damping * state.mass) / frequency
	else
		state.tension = config.tension or state.tension
		state.friction = config.friction or state.friction
	end

	if config.position then
		setPosition(self, config.position)
	end

	if config.velocity then
		setVelocity(self, config.velocity)
	end

	if config.impulse then
		self:impulse(config.impulse)
	end
end

function Spring.to<T>(self: SpringInternal<T>, value: T, config: SpringConfig<T>?)
	if config then
		self:configure(config)
	end
	setGoal(self, value)
end

function Spring.stop<T>(self: SpringInternal<T>)
	self.__state.started = false
	heartbeat.disconnect(self)
end

function Spring.start<T>(self: SpringInternal<T>)
	self.__state.started = true
	if not self.__state.complete then
		heartbeat.connect(self)
	end
end

function Spring.onStep<T>(self: SpringInternal<T>, callback: (value: T, deltaTime: number) -> ()): () -> ()
	return self.__state.onStep.connect(callback)
end

function Spring.onComplete<T>(self: SpringInternal<T>, callback: (value: T) -> ()): () -> ()
	return self.__state.onComplete.connect(callback)
end

(Spring :: any).__index = function(self: SpringInternal, key: any): any
	if key == "position" then
		return intermediate.getValue(self.__state.position)
	elseif key == "velocity" then
		return intermediate.getValue(self.__state.velocity)
	elseif key == "goal" then
		return intermediate.getValue(self.__state.goal)
	elseif key == "complete" then
		return self.__state.complete
	else
		return Spring[key]
	end
end

(Spring :: any).__newindex = function(self: SpringInternal, key: any, value: any)
	if key == "position" then
		setPosition(self, value)
	elseif key == "velocity" then
		setVelocity(self, value)
	elseif key == "goal" then
		setGoal(self, value)
	elseif key == "complete" then
		warn("Cannot set 'complete' property directly. Use 'stop()' to stop the spring.")
	else
		rawset(self :: any, key, value)
	end
end

return createSpring
