local Ripple = require(script.Parent.Ripple)
local useMotion = require(script.useMotion)
local useSpring = require(script.useSpring)
local useTween = require(script.useTween)

export type Animatable = Ripple.Animatable
export type Easing = Ripple.Easing
export type Motion<T = any> = Ripple.Motion<T>
export type MotionOptions<T = any> = Ripple.MotionOptions<T>
export type Spring<T = any> = Ripple.Spring<T>
export type SpringOptions<T = any> = Ripple.SpringOptions<T>
export type Tween<T = any> = Ripple.Tween<T>
export type TweenOptions<T = any> = Ripple.TweenOptions<T>

return {
	config = Ripple.config,
	easing = Ripple.easing,
	createMotion = Ripple.createMotion,
	createSpring = Ripple.createSpring,
	createTween = Ripple.createTween,
	useMotion = useMotion,
	useSpring = useSpring,
	useTween = useTween,
}
