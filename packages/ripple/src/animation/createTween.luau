local ease = require("../utils/ease")
local heartbeat = require("../heartbeat")
local intermediate = require("../utils/intermediate")
local signal = require("../utils/signal")
local types = require("../types")

type Animatable = types.Animatable
type Intermediate<T> = intermediate.Intermediate<T>
type Signal<T> = signal.Signal<T>

export type TweenConfig<T = any> = {
	start: boolean?,
	duration: number?,
	easing: Enum.EasingStyle?,
	direction: Enum.EasingDirection?,
	repeats: number?,
	reverses: boolean?,
	position: T?,
}

export type TweenState<T = any> = {
	position: Intermediate<T>,
	from: Intermediate<T>,
	goal: Intermediate<T>,

	duration: number,
	easing: Enum.EasingStyle?,
	direction: Enum.EasingDirection?,
	repeats: number,
	reverses: boolean,

	elapsed: number,
	started: boolean,
	complete: boolean,

	onStep: Signal<(value: T, deltaTime: number) -> ()>,
	onComplete: Signal<(value: T) -> ()>,
}

type TweenApi<T = any, U = any> = {
	onStep: (self: U, callback: (value: T, deltaTime: number) -> ()) -> () -> (),
	onComplete: (self: U, callback: (value: T) -> ()) -> () -> (),

	step: (self: U, deltaTime: number) -> T,
	to: (self: U, goal: T, config: TweenConfig<T>?) -> (),
	configure: (self: U, config: TweenConfig<T>) -> (),

	start: (self: U) -> (),
	stop: (self: U) -> (),
	destroy: (self: U) -> (),
}

type TweenInternal<T = any> = TweenApi<T, TweenInternal<T>> & {
	__state: TweenState<T>,
}

export type Tween<T = any> = TweenApi<T, Tween<T>> & {
	position: T,
	from: T,
	goal: T,
	complete: boolean,
}

local Tween = {} :: TweenInternal

local function createTween<T>(initialValue: T & Animatable, config: TweenConfig<T>?): Tween<T>
	local config: TweenConfig<T> = config or {}

	local state: TweenState<T> = {
		position = intermediate.create(config.position or initialValue),
		from = intermediate.create(config.position or initialValue),
		goal = intermediate.create(config.position or initialValue),

		duration = config.duration or 1,
		repeats = config.repeats or 1,
		reverses = config.reverses or false,

		elapsed = 0,
		started = config.start or false,
		complete = true,

		onStep = signal(),
		onComplete = signal(),
	}

	return setmetatable({
		__state = state,
	}, Tween) :: any
end

local function resumeFromCurrentPosition<T>(self: TweenInternal<T>)
	self.__state.complete = false
	self.__state.elapsed = 0
	intermediate.assign(self.__state.from, self.__state.position)
	if self.__state.started then
		heartbeat.connect(self)
	end
end

local function setPosition<T>(self: TweenInternal<T>, value: T)
	intermediate.setValue(self.__state.position, value)
	resumeFromCurrentPosition(self)
end

local function setGoal<T>(self: TweenInternal<T>, value: T)
	intermediate.setValue(self.__state.goal, value)
	resumeFromCurrentPosition(self)
end

function Tween.step<T>(self: TweenInternal<T>, deltaTime: number): T
	local state = self.__state

	if state.complete then
		return intermediate.getValue(state.position)
	end

	state.elapsed += deltaTime

	local progress = math.clamp(state.elapsed / state.duration, 0, state.repeats)
	local alpha = ease(progress, state.easing, state.direction, state.repeats, state.reverses)

	state.complete = progress == state.repeats

	local position = state.position
	local from = state.from
	local goal = state.goal

	intermediate.lerp(position, from, goal, alpha)

	local value = intermediate.getValue(position)

	state.onStep.fire(value, deltaTime)

	if state.complete then
		heartbeat.disconnect(self)
		state.onComplete.fire(value)
	end

	return value
end

function Tween.configure<T>(self: TweenInternal<T>, config: TweenConfig<T>)
	local state = self.__state

	state.duration = config.duration or state.duration
	state.easing = config.easing or state.easing
	state.direction = config.direction or state.direction
	state.repeats = config.repeats or state.repeats
	state.reverses = config.reverses or state.reverses

	if config.position then
		setPosition(self, config.position)
	else
		resumeFromCurrentPosition(self)
	end
end

function Tween.to<T>(self: TweenInternal<T>, value: T, config: TweenConfig<T>?)
	if config then
		self:configure(config)
	end
	setGoal(self, value)
end

function Tween.stop<T>(self: TweenInternal<T>)
	self.__state.started = false
	heartbeat.disconnect(self)
end

function Tween.start<T>(self: TweenInternal<T>)
	self.__state.started = true
	if not self.__state.complete then
		heartbeat.connect(self)
	end
end

function Tween.onStep<T>(self: TweenInternal<T>, callback: (value: T, deltaTime: number) -> ()): () -> ()
	return self.__state.onStep.connect(callback)
end

function Tween.onComplete<T>(self: TweenInternal<T>, callback: (value: T) -> ()): () -> ()
	return self.__state.onComplete.connect(callback)
end

(Tween :: any).__index = function(self: TweenInternal, key: any): any
	if key == "position" then
		return intermediate.getValue(self.__state.position)
	elseif key == "from" then
		return intermediate.getValue(self.__state.from)
	elseif key == "goal" then
		return intermediate.getValue(self.__state.goal)
	elseif key == "complete" then
		return self.__state.complete
	else
		return Tween[key]
	end
end

(Tween :: any).__newindex = function(self: TweenInternal, key: any, value: any)
	if key == "position" or key == "from" then
		setPosition(self, value)
	elseif key == "goal" then
		setGoal(self, value)
	elseif key == "complete" then
		warn("Cannot set 'complete' property directly. Use 'stop()' to stop the tween.")
	else
		rawset(self :: any, key, value)
	end
end

return createTween
