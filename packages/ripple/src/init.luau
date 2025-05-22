local config = require("@self/config")
local createSequence = require("@self/animation/createSequence")
local createSpring = require("@self/animation/createSpring")
local createTween = require("@self/animation/createTween")
local heartbeat = require("@self/heartbeat")
local types = require("@self/types")

export type Animatable = types.Animatable
export type Sequence<T = any> = createSequence.Sequence<T>
export type SequenceKeypoint<T = any> = createSequence.SequenceKeypoint<T>
export type Spring<T = any> = createSpring.Spring<T>
export type SpringConfig<T = any> = createSpring.SpringConfig<T>
export type Tween<T = any> = createTween.Tween<T>
export type TweenConfig<T = any> = createTween.TweenConfig<T>
export type Easing = createTween.Easing

return {
	config = config,
	heartbeat = heartbeat,
	createSequence = createSequence,
	createSpring = createSpring,
	createTween = createTween,
}
