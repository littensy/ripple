local createMotion = require("./createMotion")
local createSpring = require("./createSpring")
local createTween = require("./createTween")
local heartbeat = require("../heartbeat")
local signal = require("../utils/signal")

type MotionConfig<T> = createMotion.MotionConfig<T>
type SpringConfig<T> = createSpring.SpringConfig<T>
type TweenConfig<T> = createTween.TweenConfig<T>
type FireSignal<T...> = signal.FireSignal<T...>
type SubscribeSignal<T...> = signal.SubscribeSignal<T...>

export type SequenceKeypoint<T = any> = {
	time: number,
	goal: T,
	spring: SpringConfig<T>?,
	tween: TweenConfig<T>?,
	start: nil,
}

type SequenceApi<T> = {
	onChange: (callback: (value: T, deltaTime: number) -> ()) -> () -> (),
	onComplete: (callback: (value: T) -> ()) -> () -> (),

	step: (deltaTime: number) -> T,
	idle: () -> boolean,

	loop: () -> (),
	start: () -> (),
	stop: () -> (),
	destroy: () -> (),
}

export type Sequence<T = any> = SequenceApi<T> & {
	time: number,
	position: T,
	velocity: T,
	goal: T,
}

local function createSequence<T>(initialValue: T, keypoints: { SequenceKeypoint<T> }): Sequence<T>
	local motion = createMotion(initialValue)

	local id = heartbeat.id()
	local elapsed = 0
	local current: SequenceKeypoint<T>?

	local looped = false
	local started = false
	local complete = false

	local onChange: SubscribeSignal<(T, number)>, fireChange: FireSignal<(T, number)> = signal()
	local onComplete: SubscribeSignal<T>, fireComplete: FireSignal<T> = signal()

	local function getNextKeypoint(dt: number): (SequenceKeypoint<T>, boolean)
		local previous = keypoints[1]
		elapsed += dt

		for _, keypoint in keypoints do
			if keypoint.time > elapsed then
				return previous, false
			end
			previous = keypoint
		end

		return previous, true
	end

	local function updateKeypoint(keypoint: SequenceKeypoint<T>)
		motion.configure(keypoint)

		if keypoint.spring then
			motion.spring(keypoint.goal)
		elseif keypoint.tween then
			motion.tween(keypoint.goal)
		else
			motion.goal = keypoint.goal
		end

		current = keypoint
	end

	local function step(dt: number): T
		if complete then
			return motion.position
		end

		local keypoint, isLastKeypoint = getNextKeypoint(dt)
		local position = motion.step(dt)

		if keypoint ~= current then
			updateKeypoint(keypoint)
			dt = elapsed - keypoint.time
			position = motion.step(dt)
		end

		fireChange(position, dt)

		if isLastKeypoint and motion.idle() then
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
		if motion.position ~= value then
			motion.position = value
			resumeFromCurrentTime()
			fireChange(value, 0)
		end
	end

	local function setVelocity(value: T)
		if current and current.tween then
			return
		end

		if motion.velocity ~= value then
			motion.velocity = value
			resumeFromCurrentTime()
		end
	end

	local function setTime(time: number)
		elapsed = time
		resumeFromCurrentTime()
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

	local function loop()
		looped = true
		start()
		resumeFromCurrentTime()
	end

	local function getter(_, key: any): any
		if key == "time" then
			return elapsed
		else
			return motion[key]
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
			warn(debug.traceback("Cannot set 'goal' in a sequence.", 2))
		else
			rawset(self, key, value)
		end
	end

	local sequence: SequenceApi<T> = {
		onChange = onChange,
		onComplete = onComplete,
		step = step,
		idle = idle,
		loop = loop,
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
