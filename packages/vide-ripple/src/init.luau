local Ripple = require(script.Parent.Ripple)
local useMotion = require(script.useMotion)
local useSequence = require(script.useSequence)
local useSpring = require(script.useSpring)
local useTween = require(script.useTween)

export type Animatable = Ripple.Animatable
export type Easing = Ripple.Easing
export type Spring<T = any> = Ripple.Spring<T>
export type SpringConfig<T = any> = Ripple.SpringConfig<T>
export type Tween<T = any> = Ripple.Tween<T>
export type TweenConfig<T = any> = Ripple.TweenConfig<T>
export type Motion<T = any> = Ripple.Motion<T>
export type MotionConfig<T = any> = Ripple.MotionConfig<T>
export type Sequence<T = any> = Ripple.Sequence<T>
export type SequenceKeypoint<T = any> = Ripple.SequenceKeypoint<T>

export type VideSpring<T = any> = useSpring.VideSpring<T>
export type VideTween<T = any> = useTween.VideTween<T>
export type VideMotion<T = any> = useMotion.VideMotion<T>
export type VideSequence<T = any> = useSequence.VideSequence<T>

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
