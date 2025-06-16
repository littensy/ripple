local intermediate = require("./utils/intermediate")
local scheduler = require("@self/scheduler")
local signal = require("./utils/signal")
local types = require("@self/types")

type Animatable = types.Animatable
type Intermediate<Value> = intermediate.Intermediate<Value>

export type SpringState<Value = any> = types.SpringState<Value>

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

return createSpring
