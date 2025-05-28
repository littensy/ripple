local createSpring = require("./createSpring")
local createTween = require("./createTween")
local heartbeat = require("../heartbeat")
local signal = require("../utils/signal")
local types = require("../types")

type Animatable = types.Animatable
type Spring<Value = any> = createSpring.Spring<Value>
type SpringOptions<Value = any> = createSpring.SpringOptions<Value>
type Tween<Value = any> = createTween.Tween<Value>
type TweenOptions<Value = any> = createTween.TweenOptions<Value>

type MotionLike<Value> = {
	step: (self: MotionLike<Value>, dt: number) -> Value,
	idle: (self: MotionLike<Value>) -> boolean,
	getPosition: (self: MotionLike<Value>) -> Value,
	getGoal: (self: MotionLike<Value>) -> Value,
	setPosition: (self: MotionLike<Value>, value: Value) -> (),
	setGoal: (self: MotionLike<Value>, value: Value) -> (),
}

export type MotionOptions<Value = any> = {
	start: boolean?,
	spring: SpringOptions<Value>?,
	tween: TweenOptions<Value>?,
}

type MotionState<Value> = {
	spring: Spring<Value>,
	tween: Tween<Value>,
	current: MotionLike<Value>,
	started: boolean,
	complete: boolean,
	onChange: signal.SubscribeSignal<(Value, number)>,
	onComplete: signal.SubscribeSignal<Value>,
	fireComplete: signal.FireSignal<Value>,
}

export type Motion<Value> = {
	state: MotionState<Value>,

	setPosition: (self: Motion<Value>, value: Value) -> (),
	setVelocity: (self: Motion<Value>, value: Value) -> (),
	setGoal: (self: Motion<Value>, value: Value, options: MotionOptions<Value>?) -> (),

	getPosition: (self: Motion<Value>) -> Value,
	getVelocity: (self: Motion<Value>) -> Value,
	getGoal: (self: Motion<Value>) -> Value,

	onChange: (self: Motion<Value>, callback: (value: Value, deltaTime: number) -> ()) -> () -> (),
	onComplete: (self: Motion<Value>, callback: (value: Value) -> ()) -> () -> (),

	step: (self: Motion<Value>, deltaTime: number) -> Value,
	spring: (self: Motion<Value>, goal: Value, options: SpringOptions<Value>?) -> (),
	tween: (self: Motion<Value>, goal: Value, options: TweenOptions<Value>?) -> (),
	idle: (self: Motion<Value>) -> boolean,
	configure: (self: Motion<Value>, options: MotionOptions<Value>) -> (),

	start: (self: Motion<Value>) -> (),
	stop: (self: Motion<Value>) -> (),
	destroy: (self: Motion<Value>) -> (),

	scheduleUpdate: (self: Motion<Value>) -> (),
	prepareSpring: (self: Motion<Value>) -> (),
	prepareTween: (self: Motion<Value>) -> (),
}

local Motion = {} :: Motion<Animatable>
(Motion :: any).__index = Motion

local function omitStartOption<T>(inputOptions: T): T
	local options: any = inputOptions

	if options == nil or options.start ~= true then
		return options
	else
		local result: any = table.clone(options)
		result.start = nil
		return result
	end
end

local function createMotion<Value>(initialValue: Value, options: MotionOptions<Value>?): Motion<Value>
	local spring: Spring<Value> = createSpring(initialValue, options and omitStartOption(options.spring))
	local tween: Tween<Value> = createTween(initialValue, options and omitStartOption(options.tween))
	local current: MotionLike<Value> = if not options or not options.tween then spring else tween

	local onChange, fireChange = signal()
	local onComplete, fireComplete = signal()

	local state: MotionState<Value> = {
		spring = spring,
		tween = tween,
		current = current,
		started = false,
		complete = true,
		onChange = onChange,
		onComplete = onComplete,
		fireComplete = fireComplete,
	}

	local self: Motion<Value> = setmetatable({
		state = state,
	}, Motion) :: any

	if options and options.start then
		self:start()
	end

	spring:onChange(function(value: Value, deltaTime: number)
		if state.current == spring then
			fireChange(value, deltaTime)
		end
	end)

	tween:onChange(function(value: Value, deltaTime: number)
		if state.current == tween then
			fireChange(value, deltaTime)
		end
	end)

	return self
end

function Motion:scheduleUpdate()
	self.state.complete = false

	if self.state.started then
		heartbeat.connect(self)
	end
end

function Motion:prepareSpring()
	local state = self.state

	if state.current ~= state.spring then
		state.spring:setPosition(state.tween:getPosition())
		state.current = state.spring
	end
end

function Motion:prepareTween()
	local state = self.state

	if state.current ~= state.tween then
		state.tween:setPosition(state.spring:getPosition())
		state.spring:halt()
		state.current = state.tween
	end
end

function Motion:start()
	self.state.started = true

	if not self.state.complete then
		heartbeat.connect(self)
	end
end

function Motion:stop()
	self.state.started = false
	heartbeat.disconnect(self)
end

function Motion:idle(): boolean
	return self.state.complete
end

function Motion:step(dt: number)
	local state = self.state

	if state.complete then
		return state.current:getPosition()
	end

	local position = state.current:step(dt)

	if state.current:idle() then
		state.complete = true
		heartbeat.disconnect(self)
		state.fireComplete(position)
	end

	return position
end

function Motion:configure(options: MotionOptions)
	if options.spring then
		self.state.spring:configure(options.spring)
	end

	if options.tween then
		self.state.tween:configure(options.tween)
	end

	if not self.state.current:idle() then
		self:scheduleUpdate()
	end
end

function Motion:getPosition(): Animatable
	return self.state.current:getPosition()
end

function Motion:getVelocity(): Animatable
	return self.state.spring:getVelocity()
end

function Motion:getGoal(): Animatable
	return self.state.current:getGoal()
end

function Motion:setPosition(value: Animatable)
	self.state.current:setPosition(value)

	if not self.state.current:idle() then
		self:scheduleUpdate()
	end
end

function Motion:setVelocity(value: Animatable)
	if self.state.current == self.state.spring then
		self.state.spring:setVelocity(value)

		if not self.state.current:idle() then
			self:scheduleUpdate()
		end
	end
end

function Motion:setGoal(value: Animatable, options: MotionOptions?)
	if options then
		if options.spring then
			return self:spring(value, options.spring)
		elseif options.tween then
			return self:tween(value, options.tween)
		end
	end

	self.state.current:setGoal(value)

	if not self.state.current:idle() then
		self:scheduleUpdate()
	end
end

function Motion:spring(value: Animatable, options: SpringOptions?)
	self:prepareSpring()
	self.state.spring:setGoal(value, options)

	if not self.state.spring:idle() then
		self:scheduleUpdate()
	end
end

function Motion:tween(value: Animatable, options: TweenOptions?)
	self:prepareTween()
	self.state.tween:setGoal(value, options)

	if not self.state.tween:idle() then
		self:scheduleUpdate()
	end
end

function Motion:onChange(callback: (value: Animatable, deltaTime: number) -> ()): () -> ()
	return self.state.onChange(callback)
end

function Motion:onComplete(callback: (value: Animatable) -> ()): () -> ()
	return self.state.onComplete(callback)
end

function Motion:destroy()
	self:stop()
end

return createMotion
