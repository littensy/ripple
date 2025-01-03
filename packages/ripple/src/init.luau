local config = require(script.config)
local createSpring = require(script.createSpring)
local convert = require(script.utils.convert)

export type Animatable = convert.Animatable
export type SpringConfig<T> = createSpring.SpringConfig<T>
export type Spring<T> = createSpring.Spring<T>

return {
	config = config,
	createSpring = createSpring,
}
