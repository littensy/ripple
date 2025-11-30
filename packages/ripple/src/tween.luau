local easing = require("./easing")
local interpolate = require("./utils/interpolate")
local merge = require("./utils/merge")
local schedule = require("./utils/schedule")
local signal = require("./utils/signal")
local types = require("./types")

type Animatable = types.Animatable
type Easing = easing.Easing

export type TweenState<Value = any> = {
	position: Value,
	from: Value,
	goal: Value,
	easingFunction: (number) -> number,
	duration: number,
	repeats: number,
	reverses: boolean,
	elapsed: number,
	started: boolean,
	complete: boolean,
	onChange: signal.SubscribeSignal<(Value, number)>,
	fireChange: signal.FireSignal<(Value, number)>,
	onComplete: signal.SubscribeSignal<Value>,
	fireComplete: signal.FireSignal<Value>,
}

export type TweenOptions<Value = any> = {
	start: boolean?,
	easing: Easing?,
	duration: number?,
	repeats: number?,
	reverses: boolean?,
	position: Value?,
}

export type Tween<Value = any> = {
	state: TweenState<Value>,

	setPosition: (self: Tween<Value>, value: Value) -> (),
	setGoal: (self: Tween<Value>, value: Value, options: TweenOptions<Value>?) -> (),

	getPosition: (self: Tween<Value>) -> Value,
	getFrom: (self: Tween<Value>) -> Value,
	getGoal: (self: Tween<Value>) -> Value,

	onChange: (self: Tween<Value>, callback: (value: Value, deltaTime: number) -> ()) -> () -> (),
	onComplete: (self: Tween<Value>, callback: (value: Value) -> ()) -> () -> (),

	step: (self: Tween<Value>, deltaTime: number) -> Value,
	idle: (self: Tween<Value>) -> boolean,
	configure: (self: Tween<Value>, options: TweenOptions<Value>) -> (),

	start: (self: Tween<Value>) -> (),
	stop: (self: Tween<Value>) -> (),
	destroy: (self: Tween<Value>) -> (),

	resumeFromCurrentPosition: (self: Tween<Value>) -> (),
}

local Tween = {} :: Tween<Animatable>
(Tween :: any).__index = Tween

local function getAlpha(progress: number, repeats: number, reverses: boolean): number
	if repeats < 0 then
		repeats = math.huge
	end

	if repeats > 1 and progress >= 1 then
		if reverses then
			return math.abs((progress - 1) % 2 - 1)
		elseif progress < repeats then
			return progress % 1
		end
		return 1
	end

	return progress
end

local scheduler = schedule("Tween", function<T>(state: TweenState<T>, dt, remove): T
	if state.complete then
		remove(state)
		return state.position
	end

	state.elapsed += dt

	local progress = math.clamp(state.elapsed / state.duration, 0, state.repeats)
	local alpha = getAlpha(progress, state.repeats, state.reverses)
	local alphaEased = if alpha > 0 and alpha < 1 then state.easingFunction(alpha) else alpha
	local value = interpolate(state.from, state.goal, alphaEased)

	state.position = value
	state.fireChange(value, dt)

	if progress == state.repeats then
		remove(state)
		state.complete = true
		state.fireComplete(value)
	end

	return value
end)

local function createTween<Value>(initialValue: Value, inputOptions: TweenOptions<Value>?): Tween<Value>
	local options: TweenOptions<Value> = inputOptions or {}
	local position = options.position or initialValue

	local onChange, fireChange = signal()
	local onComplete, fireComplete = signal()

	local state: TweenState<Value> = {
		position = position,
		from = position,
		goal = position,
		easingFunction = easing.linear,
		duration = 1,
		repeats = 1,
		reverses = false,
		elapsed = 0,
		started = false,
		complete = true,
		onChange = onChange,
		fireChange = fireChange,
		onComplete = onComplete,
		fireComplete = fireComplete,
	}

	local self: Tween<Value> = setmetatable({
		state = state,
	}, Tween) :: any

	self:configure(options)

	if options.start then
		self:start()
	end

	return self
end

function Tween:resumeFromCurrentPosition()
	local state = self.state

	state.complete = false
	state.elapsed = 0
	state.from = state.position

	if state.started then
		scheduler.add(state)
	end
end

function Tween:start()
	self.state.started = true

	if not self.state.complete then
		scheduler.add(self.state)
	end
end

function Tween:stop()
	self.state.started = false
	scheduler.remove(self.state)
end

function Tween:idle(): boolean
	return self.state.complete
end

function Tween:step(dt: number): Animatable
	return scheduler.update(self.state, dt)
end

function Tween:configure(options: TweenOptions)
	local state = self.state

	state.easingFunction = easing[options.easing] or state.easingFunction
	state.duration = options.duration or state.duration
	state.repeats = options.repeats or state.repeats
	state.reverses = options.reverses or state.reverses

	if options.position then
		self:setPosition(options.position)
	end

	if not state.complete and state.elapsed ~= 0 then
		self:resumeFromCurrentPosition()
	end
end

function Tween:getPosition(): Animatable
	return self.state.position
end

function Tween:getFrom(): Animatable
	return self.state.from
end

function Tween:getGoal(): Animatable
	return self.state.goal
end

function Tween:setPosition(value: Animatable)
	local position = if type(value) == "table" then merge(self.state.position, value) else value

	if self.state.position ~= position then
		self.state.position = position
		self:resumeFromCurrentPosition()
		self.state.fireChange(position, 0)
	end
end

function Tween:setGoal(value: Animatable, options: TweenOptions?)
	if options then
		self:configure(options)
	end

	local goal = if type(value) == "table" then merge(self.state.goal, value) else value

	if self.state.goal ~= goal then
		self.state.goal = goal
		self:resumeFromCurrentPosition()
	end
end

function Tween:onChange(callback: (value: Animatable, deltaTime: number) -> ()): () -> ()
	return self.state.onChange(callback)
end

function Tween:onComplete(callback: (value: Animatable) -> ()): () -> ()
	return self.state.onComplete(callback)
end

function Tween:destroy()
	self:stop()
end

return {
	scheduler = scheduler,
	createTween = createTween,
}
