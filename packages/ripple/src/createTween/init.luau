local easing = require("./easing")
local heartbeat = require("@self/heartbeat")
local merge = require("./utils/merge")
local signal = require("./utils/signal")
local types = require("@self/types")

type Animatable = types.Animatable
type Easing = easing.Easing

export type TweenState<Value = any> = types.TweenState<Value>

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
		heartbeat.connect(state)
	end
end

function Tween:start()
	self.state.started = true

	if not self.state.complete then
		heartbeat.connect(self.state)
	end
end

function Tween:stop()
	self.state.started = false
	heartbeat.disconnect(self.state)
end

function Tween:idle(): boolean
	return self.state.complete
end

function Tween:step(dt: number): Animatable
	return heartbeat.update(self.state, dt)
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

return createTween
