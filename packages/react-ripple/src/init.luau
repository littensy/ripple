local Ripple = require(script.Parent.Ripple)
local useMotion = require(script.useMotion)
local useSequence = require(script.useSequence)
local useSpring = require(script.useSpring)
local useTween = require(script.useTween)

export type Animatable = Ripple.Animatable
export type Spring<T> = Ripple.Spring<T>
export type SpringConfig<T> = Ripple.SpringConfig<T>
export type Tween<T> = Ripple.Tween<T>
export type TweenConfig<T> = Ripple.TweenConfig<T>
export type Motion<T> = Ripple.Motion<T>
export type MotionConfig<T> = Ripple.MotionConfig<T>
export type Sequence<T> = Ripple.Sequence<T>
export type SequenceKeypoint<T> = Ripple.SequenceKeypoint<T>

return {
	config = Ripple.config,
	easing = Ripple.easing,
	heartbeat = Ripple.heartbeat,
	createMotion = Ripple.createMotion,
	createSequence = Ripple.createSequence,
	createSpring = Ripple.createSpring,
	createTween = Ripple.createTween,
	useMotion = useMotion,
	useSequence = useSequence,
	useSpring = useSpring,
	useTween = useTween,
}
