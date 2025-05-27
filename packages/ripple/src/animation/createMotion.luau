local createSpring = require("./createSpring")
local createTween = require("./createTween")
local easing = require("../easing")
local heartbeat = require("../heartbeat")
local signal = require("../utils/signal")
local types = require("../types")

type Easing = easing.Easing
type Animatable = types.Animatable
type Spring<T = any> = createSpring.Spring<T>
type SpringConfig<T = any> = createSpring.SpringConfig<T>
type Tween<T = any> = createTween.Tween<T>
type TweenConfig<T = any> = createTween.TweenConfig<T>
type FireSignal<T...> = signal.FireSignal<T...>
type SubscribeSignal<T...> = signal.SubscribeSignal<T...>

export type MotionConfig<T = any> = {
	start: boolean?,
	spring: SpringConfig<T>?,
	tween: TweenConfig<T>?,
}

type MotionApi<T> = {
	onChange: (callback: (value: T, deltaTime: number) -> ()) -> () -> (),
	onComplete: (callback: (value: T) -> ()) -> () -> (),

	step: (deltaTime: number) -> T,
	spring: (goal: T, config: SpringConfig<T>?) -> (),
	tween: (goal: T, config: TweenConfig<T>?) -> (),
	idle: () -> boolean,
	configure: (config: MotionConfig<T>) -> (),

	start: () -> (),
	stop: () -> (),
	destroy: () -> (),
}

export type Motion<T = any> = MotionApi<T> & {
	position: T,
	velocity: T,
	goal: T,
}

type MotionLike<T> = {
	step: (dt: number) -> T,
	idle: () -> boolean,
	position: T,
	goal: T,
}

local function omitStartOption<T>(config: T): T
	local config: any = config
	if config == nil or config.start ~= true then
		return config
	else
		local result: any = table.clone(config)
		result.start = nil
		return result
	end
end

local function createMotion<T>(initialValue: T & Animatable, config: MotionConfig<T>?): Motion<T>
	local config: MotionConfig<T> = config or {}

	local spring: Spring<T> = createSpring(initialValue :: Animatable, omitStartOption(config.spring))
	local tween: Tween<T> = createTween(initialValue :: Animatable, omitStartOption(config.tween))
	local current: MotionLike<T> = if not config.tween then spring else tween

	local id = heartbeat.id()
	local started = false
	local complete = true

	local onChange: SubscribeSignal<(T, number)>, fireChange: FireSignal<(T, number)> = signal()
	local onComplete: SubscribeSignal<T>, fireComplete: FireSignal<T> = signal()

	local function initSpring()
		if current ~= spring then
			spring.position = tween.position
			current = spring
		end
	end

	local function initTween()
		if current ~= tween then
			tween.position = spring.position
			spring.halt()
			current = tween
		end
	end

	local function step(dt: number): T
		if complete then
			return current.position
		end

		local position = current.step(dt)

		fireChange(position, dt)

		if current.idle() then
			complete = true
			heartbeat.disconnect(id)
			fireComplete(position)
		end

		return position
	end

	local function scheduleUpdate()
		complete = false
		if started then
			heartbeat.connect(id, step)
		end
	end

	local function setPosition(value: T)
		if current.position ~= value then
			current.position = value
			scheduleUpdate()
			fireChange(value, 0)
		end
	end

	local function setVelocity(value: T)
		if current == spring and spring.velocity ~= value then
			spring.velocity = value
			scheduleUpdate()
		end
	end

	local function setGoal(value: T)
		if current.goal ~= value then
			current.goal = value
			scheduleUpdate()
		end
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

	local function configure(config: MotionConfig<T>)
		if config.spring then
			spring.configure(omitStartOption(config.spring))
		end

		if config.tween then
			tween.configure(omitStartOption(config.tween))
		end

		if config.spring or config.tween then
			scheduleUpdate()
		end
	end

	local function springTo(goal: T, config: SpringConfig<T>?)
		initSpring()

		if config then
			spring.to(goal, omitStartOption(config))
			scheduleUpdate()
		elseif spring.goal ~= goal then
			spring.goal = goal
			scheduleUpdate()
		end
	end

	local function tweenTo(goal: T, config: TweenConfig<T>?)
		initTween()

		if config then
			tween.to(goal, omitStartOption(config))
			scheduleUpdate()
		elseif tween.goal ~= goal then
			tween.goal = goal
			scheduleUpdate()
		end
	end

	local function getter(_, key: any): any
		if key == "position" then
			return current.position
		elseif key == "velocity" then
			return spring.velocity
		elseif key == "goal" then
			return current.goal
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

	local motion: MotionApi<T> = {
		onChange = onChange,
		onComplete = onComplete,
		spring = springTo,
		tween = tweenTo,
		configure = configure,
		idle = idle,
		step = step,
		start = start,
		stop = stop,
		destroy = stop,
	}

	if config.start then
		start()
	end

	return setmetatable(motion, {
		__index = getter,
		__newindex = setter,
	}) :: any
end

return createMotion
