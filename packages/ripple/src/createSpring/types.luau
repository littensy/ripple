local intermediate = require("../utils/intermediate")
local signal = require("../utils/signal")
local types = require("../types")

export type Animatable = types.Animatable

type Intermediate<Value> = intermediate.Intermediate<Value>

export type SpringState<Value = any> = {
	position: Intermediate<Value>,
	velocity: Intermediate<Value>,
	goal: Intermediate<Value>,
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
