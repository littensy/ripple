local signal = require("../utils/signal")
local types = require("../types")

export type Animatable = types.Animatable

export type TweenState<Value = any> = {
	position: Value,
	from: Value,
	goal: Value,
	easingFunction: (number) -> number,
	duration: number,
	repeats: number,
	reverses: boolean,
	elapsed: number,
	started: boolean,
	complete: boolean,
	onChange: signal.SubscribeSignal<(Value, number)>,
	fireChange: signal.FireSignal<(Value, number)>,
	onComplete: signal.SubscribeSignal<Value>,
	fireComplete: signal.FireSignal<Value>,
}

return {}
