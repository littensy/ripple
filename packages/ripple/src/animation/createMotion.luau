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

type SpringMotionConfig<T> = {
	type: "spring",
	start: boolean?,

	-- Spring options
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

	-- Tween options
	easing: nil,
	duration: nil,
	repeats: nil,
	reverses: nil,
}

type TweenMotionConfig<T = any> = {
	type: "tween",
	start: boolean?,

	-- Tween options
	easing: Easing?,
	duration: number?,
	repeats: number?,
	reverses: boolean?,
	position: T?,

	-- Spring options
	tension: nil,
	friction: nil,
	mass: nil,
	dampingRatio: nil,
	frequency: nil,
	precision: nil,
	restVelocity: nil,
	velocity: nil,
	impulse: nil,
}

export type MotionConfig<T = any> = SpringMotionConfig<T> | TweenMotionConfig<T>

type MotionApi<T> = {
	onChange: (callback: (value: T, deltaTime: number) -> ()) -> () -> (),
	onComplete: (callback: (value: T) -> ()) -> () -> (),
	spring: (goal: T, config: SpringConfig<T>?) -> (),
	tween: (goal: T, config: TweenConfig<T>?) -> (),
	configure: (config: MotionConfig<T>) -> (),
	step: (deltaTime: number) -> T,
	start: () -> (),
	stop: () -> (),
	destroy: () -> (),
}

export type Motion<T = any> = MotionApi<T> & {
	position: T,
	velocity: T,
	goal: T,
	complete: boolean,
}

type MotionLike<T> = {
	step: (dt: number) -> T,
	position: T,
	goal: T,
	complete: boolean,
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
	local spring: Spring<T>
	local tween: Tween<T>
	local current: MotionLike<T>

	if not config or config.type == "spring" then
		spring = createSpring(initialValue :: Animatable, omitStartOption(config))
		tween = createTween(initialValue :: Animatable)
		current = spring
	else
		spring = createSpring(initialValue :: Animatable)
		tween = createTween(initialValue :: Animatable, omitStartOption(config))
		current = tween
	end

	local initialVelocity = spring.velocity

	local id = heartbeat.id()
	local started = false
	local complete = true

	local onChange: SubscribeSignal<(T, number)>, fireChange: FireSignal<(T, number)> = signal()
	local onComplete: SubscribeSignal<T>, fireComplete: FireSignal<T> = signal()

	local function initSpring()
		if current ~= spring then
			spring.position = tween.position
			spring.velocity = initialVelocity
			current = spring
		end
	end

	local function initTween()
		if current ~= tween then
			tween.position = spring.position
			current = tween
		end
	end

	local function step(dt: number): T
		if complete then
			return current.position
		end

		local position = current.step(dt)

		fireChange(position, dt)

		if current.complete then
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
		if config.type == "spring" then
			spring.configure(omitStartOption(config))
		else
			tween.configure(omitStartOption(config))
		end

		scheduleUpdate()
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
			return if current == spring then spring.velocity else initialVelocity
		elseif key == "goal" then
			return current.goal
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
			warn(debug.traceback("Cannot set 'complete' property directly. Use 'stop()' to stop the sequence.", 2))
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
		step = step,
		start = start,
		stop = stop,
		destroy = stop,
	}

	if config and config.start then
		start()
	end

	return setmetatable(motion, {
		__index = getter,
		__newindex = setter,
	}) :: any
end

return createMotion
