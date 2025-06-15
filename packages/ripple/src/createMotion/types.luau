local createSpring = require("../createSpring")
local createTween = require("../createTween")
local signal = require("../utils/signal")
local types = require("../types")

export type Animatable = types.Animatable

type Spring<Value = any> = createSpring.Spring<Value>
type SpringOptions<Value = any> = createSpring.SpringOptions<Value>
type Tween<Value = any> = createTween.Tween<Value>
type TweenOptions<Value = any> = createTween.TweenOptions<Value>

export type MotionLike<Value> = {
	step: (self: MotionLike<Value>, dt: number) -> Value,
	idle: (self: MotionLike<Value>) -> boolean,
	getPosition: (self: MotionLike<Value>) -> Value,
	getGoal: (self: MotionLike<Value>) -> Value,
	setPosition: (self: MotionLike<Value>, value: Value) -> (),
	setGoal: (self: MotionLike<Value>, value: Value) -> (),
}

export type MotionState<Value> = {
	spring: Spring<Value>,
	tween: Tween<Value>,
	current: MotionLike<Value>,
	started: boolean,
	complete: boolean,
	onChange: signal.SubscribeSignal<(Value, number)>,
	onComplete: signal.SubscribeSignal<Value>,
	fireComplete: signal.FireSignal<Value>,
}

return {}
