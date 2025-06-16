local intermediate = require("../utils/intermediate")
local signal = require("../utils/signal")
local types = require("../types")

export type Animatable = types.Animatable

export type SpringState<Value = any> = {
	position: intermediate.Intermediate<Value>,
	velocity: intermediate.Intermediate<Value>,
	goal: intermediate.Intermediate<Value>,
	dampingRatio: number,
	frequency: number,
	restPosition: number,
	restVelocity: number,
	started: boolean,
	complete: boolean,
	onChange: signal.SubscribeSignal<(Value, number)>,
	fireChange: signal.FireSignal<(Value, number)>,
	onComplete: signal.SubscribeSignal<Value>,
	fireComplete: signal.FireSignal<Value>,
}

return {}
