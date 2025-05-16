local easing = require("../utils/easing")
local heartbeat = require("../heartbeat")
local intermediate = require("../utils/intermediate")
local signal = require("../utils/signal")
local types = require("../types")

type Easing = easing.Easing
type Animatable = types.Animatable
type Intermediate<T> = intermediate.Intermediate<T>
type Signal<T> = signal.Signal<T>

export type TweenConfig<T> = {
	start: boolean?,
	easing: Easing?,
	duration: number?,
	repeats: number?,
	reverses: boolean?,
	position: T?,
}

type TweenApi<T> = {
	onStep: (callback: (value: T, deltaTime: number) -> ()) -> () -> (),
	onComplete: (callback: (value: T) -> ()) -> () -> (),

	step: (deltaTime: number) -> T,
	to: (goal: T, config: TweenConfig<T>?) -> (),
	configure: (config: TweenConfig<T>) -> (),

	start: () -> (),
	stop: () -> (),
	destroy: () -> (),
}

export type Tween<T = any> = TweenApi<T> & {
	position: T,
	from: T,
	goal: T,
	complete: boolean,
}

local function getAlpha(progress: number, repeats: number, reverses: boolean): number
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

local function createTween<T>(initialValue: T & Animatable, config: TweenConfig<T>?): Tween<T>
	local config: TweenConfig<T> = config or {}

	local position = intermediate.create(config.position or initialValue)
	local from = intermediate.create(config.position or initialValue)
	local goal = intermediate.create(config.position or initialValue)

	local easingFunction = easing[config.easing :: Easing] or easing["linear" :: "linear"]
	local duration = config.duration or 1
	local repeats = config.repeats or 1
	local reverses = config.reverses or false

	local id = heartbeat.id()
	local elapsed = 0
	local started = config.start or false
	local complete = true

	local onStep = signal()
	local onComplete = signal()

	local function step(deltaTime: number): T
		if complete then
			return intermediate.getValue(position)
		end

		elapsed += deltaTime

		local progress = math.clamp(elapsed / duration, 0, repeats)
		local alpha = getAlpha(progress, repeats, reverses)
		local value = if alpha > 0 and alpha < 1 then easingFunction(alpha) else alpha

		complete = progress == repeats

		local position = position
		local from = from
		local goal = goal

		intermediate.lerp(position, from, goal, value)

		local value = intermediate.getValue(position)

		onStep.fire(value, deltaTime)

		if complete then
			heartbeat.disconnect(id)
			onComplete.fire(value)
		end

		return value
	end

	local function resumeFromCurrentPosition()
		complete = false
		elapsed = 0
		intermediate.assign(from, position)
		if started then
			heartbeat.connect(id, step)
		end
	end

	local function setPosition(value: T)
		intermediate.setValue(position, value)
		resumeFromCurrentPosition()
	end

	local function setGoal(value: T)
		intermediate.setValue(goal, value)
		resumeFromCurrentPosition()
	end

	local function configure(config: TweenConfig<T>)
		easingFunction = easing[config.easing :: Easing] or easingFunction
		duration = config.duration or duration
		repeats = config.repeats or repeats
		reverses = config.reverses or reverses

		if config.position then
			setPosition(config.position)
		else
			resumeFromCurrentPosition()
		end
	end

	local function to(value: T, config: TweenConfig<T>?)
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

	local function getter(_: any, key: any): any
		if key == "position" then
			return intermediate.getValue(position)
		elseif key == "from" then
			return intermediate.getValue(from)
		elseif key == "goal" then
			return intermediate.getValue(goal)
		elseif key == "complete" then
			return complete
		else
			return nil
		end
	end

	local function setter(self: any, key: any, value: any)
		if key == "position" or key == "from" then
			setPosition(value)
		elseif key == "goal" then
			setGoal(value)
		elseif key == "complete" then
			warn("Cannot set 'complete' property directly. Use 'stop()' to stop the tween.")
		else
			rawset(self, key, value)
		end
	end

	local tween: TweenApi<T> = {
		onStep = onStep.connect,
		onComplete = onComplete.connect,
		step = step,
		to = to,
		configure = configure,
		start = start,
		stop = stop,
		destroy = stop,
	}

	if config.start then
		start()
	end

	return setmetatable(tween, {
		__index = getter,
		__newindex = setter,
	}) :: any
end

return createTween
