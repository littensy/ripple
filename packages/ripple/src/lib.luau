local config = require("./heartbeat")
local createSpring = require("./animation/createSpring")
local heartbeat = require("./heartbeat")
local types = require("./types")

export type Animatable = types.Animatable
export type Spring<T> = createSpring.Spring<T>
export type SpringConfig<T> = createSpring.SpringConfig<T>

return {
	config = config,
	heartbeat = heartbeat,
	createSpring = createSpring,
}
