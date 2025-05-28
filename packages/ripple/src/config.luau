local createSpring = require("./animation/createSpring")

type SpringOptions = createSpring.SpringOptions

return {
	default = { tension = 170, friction = 26 } :: SpringOptions,
	gentle = { tension = 120, friction = 14 } :: SpringOptions,
	wobbly = { tension = 180, friction = 12 } :: SpringOptions,
	stiff = { tension = 210, friction = 20 } :: SpringOptions,
	slow = { tension = 280, friction = 60 } :: SpringOptions,
	molasses = { tension = 280, friction = 120 } :: SpringOptions,
}
