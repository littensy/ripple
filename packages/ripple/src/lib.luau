local config = require("./config")
local createSpring = require("./animation/createSpring")
local createTween = require("./animation/createTween")
local heartbeat = require("./heartbeat")
local types = require("./types")

export type Animatable = types.Animatable
export type Spring<T = any> = createSpring.Spring<T>
export type SpringConfig<T = any> = createSpring.SpringConfig<T>
export type Tween<T = any> = createTween.Tween<T>
export type TweenConfig<T = any> = createTween.TweenConfig<T>
export type Easing = createTween.Easing

return {
	config = config,
	heartbeat = heartbeat,
	createSpring = createSpring,
	createTween = createTween,
}
