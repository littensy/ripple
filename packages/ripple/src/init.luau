local config = require("@self/config")
local createMotion = require("@self/createMotion")
local createSpring = require("@self/createSpring")
local createTween = require("@self/createTween")
local easing = require("@self/easing")
local spr = require("@self/spr")
local types = require("@self/types")

export type Animatable = types.Animatable
export type AnimatableType = types.AnimatableType
export type AnimatablePrimitive = types.AnimatablePrimitive
export type Easing = easing.Easing

export type Motion<T = any> = createMotion.Motion<T>
export type MotionOptions<T = any> = createMotion.MotionOptions<T>
export type Spring<T = any> = createSpring.Spring<T>
export type SpringOptions<T = any> = createSpring.SpringOptions<T>
export type Tween<T = any> = createTween.Tween<T>
export type TweenOptions<T = any> = createTween.TweenOptions<T>

return {
	config = config,
	easing = easing,
	spr = spr,
	createMotion = createMotion,
	createSpring = createSpring,
	createTween = createTween,
}
