local config = require("@self/config")
local easing = require("@self/easing")
local motion = require("@self/motion")
local spring = require("@self/spring")
local tween = require("@self/tween")
local types = require("@self/types")

export type Animatable = types.Animatable
export type AnimatableType = types.AnimatableType
export type AnimatablePrimitive = types.AnimatablePrimitive
export type Easing = easing.Easing

export type Motion<T = any> = motion.Motion<T>
export type MotionOptions<T = any> = motion.MotionOptions<T>
export type Spring<T = any> = spring.Spring<T>
export type SpringOptions<T = any> = spring.SpringOptions<T>
export type Tween<T = any> = tween.Tween<T>
export type TweenOptions<T = any> = tween.TweenOptions<T>

return {
	config = config,
	easing = easing,
	createMotion = motion.createMotion,
	createSpring = spring.createSpring,
	createTween = tween.createTween,
}
