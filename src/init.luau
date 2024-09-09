local types = require(script.types)

export type Motion<T = number> = types.Motion<T>

export type MotionState = types.MotionState

export type MotionSolver = types.MotionSolver

export type MotionGoal = types.MotionGoal

export type SpringOptions = types.SpringOptions
export type LinearOptions = types.LinearOptions
export type TweenOptions = types.TweenOptions

return {
	createMotion = require(script.createMotion),
	config = require(script.config),
	immediate = require(script.solvers.immediate),
	linear = require(script.solvers.linear),
	spring = require(script.solvers.spring),
	tween = require(script.solvers.tween),
}
