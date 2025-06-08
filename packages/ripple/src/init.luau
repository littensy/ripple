local config = require("@self/config")
local createMotion = require("@self/animation/createMotion")
local createSequence = require("@self/animation/createSequence")
local createSpring = require("@self/animation/createSpring")
local createTween = require("@self/animation/createTween")
local easing = require("@self/easing")
local heartbeat = require("@self/heartbeat")
local spr = require("@self/spr")
local types = require("@self/types")

export type Animatable = types.Animatable
export type Easing = easing.Easing
export type Motion<T = any> = createMotion.Motion<T>
export type MotionOptions<T = any> = createMotion.MotionOptions<T>
export type Sequence<T = any> = createSequence.Sequence<T>
export type SequenceKeypoint<T = any> = createSequence.SequenceKeypoint<T>
export type Spring<T = any> = createSpring.Spring<T>
export type SpringOptions<T = any> = createSpring.SpringOptions<T>
export type Tween<T = any> = createTween.Tween<T>
export type TweenOptions<T = any> = createTween.TweenOptions<T>

return {
	config = config,
	easing = easing,
	heartbeat = heartbeat,
	spr = spr,
	createMotion = createMotion,
	createSequence = createSequence,
	createSpring = createSpring,
	createTween = createTween,
}
