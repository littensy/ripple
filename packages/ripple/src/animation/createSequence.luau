local createSpring = require("./createSpring")
local createTween = require("./createTween")
local heartbeat = require("../heartbeat")
local signal = require("../utils/signal")
local types = require("../types")

type Animatable = types.Animatable
type Spring<T = any> = createSpring.Spring<T>
type SpringConfig<T = any> = createSpring.SpringConfig<T>
type Tween<T = any> = createTween.Tween<T>
type TweenConfig<T = any> = createTween.TweenConfig<T>
type FireSignal<T...> = signal.FireSignal<T...>
type SubscribeSignal<T...> = signal.SubscribeSignal<T...>

export type SequenceKeypoint<T = any> = {
	time: number,
	value: T,
	spring: SpringConfig<T>?,
	tween: TweenConfig<T>?,
}

type SequenceApi<T> = {
	onChange: (callback: (value: T, deltaTime: number) -> ()) -> () -> (),
	onComplete: (callback: (value: T) -> ()) -> () -> (),
	step: (deltaTime: number) -> T,
	start: () -> (),
	stop: () -> (),
	destroy: () -> (),
}

export type Sequence<T = any> = SequenceApi<T> & {
	time: number,
	position: T,
	velocity: T,
	goal: T,
	complete: boolean,
	looped: boolean,
}

type MotionLike<T> = {
	step: (dt: number) -> T,
	position: T,
	goal: T,
	complete: boolean,
}

local function createSequence<T>(initialValue: T & Animatable, keypoints: { SequenceKeypoint<T> }): Sequence<T>
	local spring: Spring<T> = createSpring(initialValue :: any)
	local tween: Tween<T> = createTween(initialValue :: any)
	local current: MotionLike<T>?

	local id = heartbeat.id()
	local elapsed = 0
	local looped = false
	local started = false
	local complete = false

	local onChange: SubscribeSignal<(T, number)>, fireChange: FireSignal<(T, number)> = signal()
	local onComplete: SubscribeSignal<T>, fireComplete: FireSignal<T> = signal()

	local function getKeypoint(): (SequenceKeypoint<T>, boolean)
		local previous = keypoints[1]
		for _, keypoint in keypoints do
			if keypoint.time > elapsed then
				return previous, false
			end
			previous = keypoint
		end
		return previous, true
	end

	local function step(dt: number): T
		if complete then
			return if current then current.position else initialValue
		end

		elapsed += dt

		local keypoint, isLastKeypoint = getKeypoint()

		if keypoint.spring and current ~= spring then
			spring.position = tween.position
			spring.goal = keypoint.value
			spring.configure(keypoint.spring)
			current = spring
		elseif keypoint.tween and current ~= tween then
			tween.position = spring.position
			tween.goal = keypoint.value
			tween.configure(keypoint.tween)
			current = tween
		end

		if not current then
			return keypoint.value
		end

		local position = current.step(dt)

		fireChange(position, dt)

		if isLastKeypoint and current.complete then
			if looped then
				elapsed = 0
			else
				complete = true
				heartbeat.disconnect(id)
			end

			fireComplete(position)
		end

		return position
	end

	local function resumeFromCurrentTime()
		complete = false
		if started then
			heartbeat.connect(id, step)
		end
	end

	local function setPosition(value: T)
		if current and current.position ~= value then
			current.position = value
			resumeFromCurrentTime()
			fireChange(value, 0)
		end
	end

	local function setVelocity(value: T)
		if current == spring and spring.velocity ~= value then
			spring.velocity = value
			resumeFromCurrentTime()
		end
	end

	local function setTime(time: number)
		elapsed = time
		resumeFromCurrentTime()
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

	local function getter(_, key: any): any
		if key == "position" then
			return if current then current.position else initialValue
		elseif key == "velocity" then
			return spring.velocity
		elseif key == "goal" then
			return if current then current.goal else initialValue
		elseif key == "complete" then
			return complete
		elseif key == "time" then
			return elapsed
		else
			return nil
		end
	end

	local function setter(self: any, key: any, value: any)
		if key == "position" then
			setPosition(value)
		elseif key == "velocity" then
			setVelocity(value)
		elseif key == "time" then
			setTime(value)
		elseif key == "goal" then
			warn("Cannot set 'goal' directly. Use 'to()' to set the goal.")
		elseif key == "complete" then
			warn("Cannot set 'complete' property directly. Use 'stop()' to stop the sequence.")
		else
			rawset(self, key, value)
		end
	end

	local sequence: SequenceApi<T> = {
		onChange = onChange,
		onComplete = onComplete,
		step = step,
		start = start,
		stop = stop,
		destroy = stop,
	}

	return setmetatable(sequence, {
		__index = getter,
		__newindex = setter,
	}) :: any
end

return createSequence
