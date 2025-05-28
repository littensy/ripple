local createMotion = require("./createMotion")
local createSpring = require("./createSpring")
local createTween = require("./createTween")
local heartbeat = require("../heartbeat")
local signal = require("../utils/signal")
local types = require("../types")

type Animatable = types.Animatable
type Motion<Value> = createMotion.Motion<Value>

export type SequenceKeypoint<Value = any> = {
	time: number,
	goal: Value,
	spring: createSpring.SpringOptions<Value>?,
	tween: createTween.TweenOptions<Value>?,
	start: nil,
}

type SequenceState<Value> = {
	motion: Motion<Value>,
	keypoints: { SequenceKeypoint<Value> },
	keypoint: SequenceKeypoint<Value>?,
	elapsed: number,
	looped: boolean,
	started: boolean,
	complete: boolean,
	onChange: signal.SubscribeSignal<(Value, number)>,
	onComplete: signal.SubscribeSignal<Value>,
	fireComplete: signal.FireSignal<Value>,
}

export type Sequence<Value = any> = {
	state: SequenceState<Value>,

	setTime: (self: Sequence<Value>, time: number) -> (),
	setPosition: (self: Sequence<Value>, value: Value) -> (),
	setVelocity: (self: Sequence<Value>, value: Value) -> (),

	getTime: (self: Sequence<Value>) -> number,
	getPosition: (self: Sequence<Value>) -> Value,
	getVelocity: (self: Sequence<Value>) -> Value,
	getGoal: (self: Sequence<Value>) -> Value,

	onChange: (self: Sequence<Value>, callback: (value: Value, deltaTime: number) -> ()) -> () -> (),
	onComplete: (self: Sequence<Value>, callback: (value: Value) -> ()) -> () -> (),

	step: (self: Sequence<Value>, deltaTime: number) -> Value,
	idle: (self: Sequence<Value>) -> boolean,

	loop: (self: Sequence<Value>) -> (),
	start: (self: Sequence<Value>) -> (),
	stop: (self: Sequence<Value>) -> (),
	destroy: (self: Sequence<Value>) -> (),

	resumeFromCurrentTime: (self: Sequence<Value>) -> (),
	getNextKeypoint: (self: Sequence<Value>, dt: number) -> (SequenceKeypoint<Value>, boolean),
	setCurrentKeypoint: (self: Sequence<Value>, keypoint: SequenceKeypoint<Value>) -> (),
}

local Sequence = {} :: Sequence<Animatable>
(Sequence :: any).__index = Sequence

local function createSequence<Value>(initialValue: Value, keypoints: { SequenceKeypoint<Value> }): Sequence<Value>
	local motion = createMotion(initialValue)
	local onComplete, fireComplete = signal()

	local state: SequenceState<Value> = {
		motion = motion,
		keypoints = keypoints,
		keypoint = nil,
		elapsed = 0,
		looped = false,
		started = false,
		complete = false,
		onChange = motion.state.onChange,
		onComplete = onComplete,
		fireComplete = fireComplete,
	}

	return setmetatable({
		state = state,
	}, Sequence) :: any
end

function Sequence:getNextKeypoint(dt: number): (SequenceKeypoint<Animatable>, boolean)
	local state = self.state
	local previous = state.keypoints[1]

	state.elapsed += dt

	for _, keypoint in state.keypoints do
		if keypoint.time > state.elapsed then
			return previous, false
		end
		previous = keypoint
	end

	return previous, true
end

function Sequence:setCurrentKeypoint(keypoint: SequenceKeypoint<Animatable>)
	self.state.motion:setGoal(keypoint.goal, keypoint)
	self.state.keypoint = keypoint
end

function Sequence:resumeFromCurrentTime()
	self.state.complete = false

	if self.state.started then
		heartbeat.connect(self)
	end
end

function Sequence:start()
	self.state.started = true

	if not self.state.complete then
		heartbeat.connect(self)
	end
end

function Sequence:stop()
	self.state.started = false
	heartbeat.disconnect(self)
end

function Sequence:loop()
	self.state.looped = true
	self:start()
	self:resumeFromCurrentTime()
end

function Sequence:idle(): boolean
	return self.state.complete
end

function Sequence:step(dt: number)
	local state = self.state
	local motion = state.motion

	if state.complete then
		return motion:getPosition()
	end

	local keypoint, isLastKeypoint = self:getNextKeypoint(dt)
	local position = motion:step(dt)

	if keypoint ~= state.keypoint then
		self:setCurrentKeypoint(keypoint)
		dt = state.elapsed - keypoint.time
		position = motion:step(dt)
	end

	if isLastKeypoint and motion:idle() then
		if state.looped then
			state.elapsed = 0
		else
			state.complete = true
			heartbeat.disconnect(self)
		end

		state.fireComplete(position)
	end

	return position
end

function Sequence:getPosition(): Animatable
	return self.state.motion:getPosition()
end

function Sequence:getVelocity(): Animatable
	return self.state.motion:getVelocity()
end

function Sequence:getGoal(): Animatable
	return self.state.motion:getGoal()
end

function Sequence:getTime(): number
	return self.state.elapsed
end

function Sequence:setPosition(value: Animatable)
	self.state.motion:setPosition(value)

	if not self.state.motion:idle() then
		self:resumeFromCurrentTime()
	end
end

function Sequence:setVelocity(value: Animatable)
	if self.state.keypoint and self.state.keypoint.tween then
		return
	end

	self.state.motion:setVelocity(value)

	if not self.state.motion:idle() then
		self:resumeFromCurrentTime()
	end
end

function Sequence:setTime(time: number)
	self.state.elapsed = time
	self:resumeFromCurrentTime()
end

function Sequence:onChange(callback: (value: Animatable, deltaTime: number) -> ()): () -> ()
	return self.state.onChange(callback)
end

function Sequence:onComplete(callback: (value: Animatable) -> ()): () -> ()
	return self.state.onComplete(callback)
end

function Sequence:destroy()
	self:stop()
end

return createSequence
