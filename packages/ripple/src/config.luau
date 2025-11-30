local spring = require("./spring")

type SpringOptions = spring.SpringOptions

return {
	default = { tension = 170, friction = 26 } :: SpringOptions,
	gentle = { tension = 120, friction = 14 } :: SpringOptions,
	wobbly = { tension = 180, friction = 12 } :: SpringOptions,
	stiff = { tension = 210, friction = 20 } :: SpringOptions,
	slow = { tension = 280, friction = 60 } :: SpringOptions,
	molasses = { tension = 280, friction = 120 } :: SpringOptions,
	figmaGentle = { tension = 100, friction = 15 } :: SpringOptions,
	figmaQuick = { tension = 300, friction = 20 } :: SpringOptions,
	figmaBouncy = { tension = 600, friction = 15 } :: SpringOptions,
	figmaSlow = { tension = 80, friction = 20 } :: SpringOptions,
}
