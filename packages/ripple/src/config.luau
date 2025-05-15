local createSpring = require("./animation/createSpring")

type SpringConfig = createSpring.SpringConfig

return {
	default = { tension = 170, friction = 26 } :: SpringConfig,
	gentle = { tension = 120, friction = 14 } :: SpringConfig,
	wobbly = { tension = 180, friction = 12 } :: SpringConfig,
	stiff = { tension = 210, friction = 20 } :: SpringConfig,
	slow = { tension = 280, friction = 60 } :: SpringConfig,
	molasses = { tension = 280, friction = 120 } :: SpringConfig,
}
