local createSpring = require("../createSpring")
local createTween = require("../createTween")
local signal = require("../utils/signal")
local types = require("../types")

export type Animatable = types.Animatable

export type MotionLike<Value> = {
	step: (self: MotionLike<Value>, dt: number) -> Value,
	idle: (self: MotionLike<Value>) -> boolean,
	getPosition: (self: MotionLike<Value>) -> Value,
	getGoal: (self: MotionLike<Value>) -> Value,
	setPosition: (self: MotionLike<Value>, value: Value) -> (),
	setGoal: (self: MotionLike<Value>, value: Value) -> (),
}

export type MotionState<Value> = {
	spring: createSpring.Spring<Value>,
	tween: createTween.Tween<Value>,
	current: MotionLike<Value>,
	started: boolean,
	complete: boolean,
	onChange: signal.SubscribeSignal<(Value, number)>,
	onComplete: signal.SubscribeSignal<Value>,
	fireComplete: signal.FireSignal<Value>,
}

return {}
