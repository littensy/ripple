local config = {
	spring = {
		default = { tension = 170, friction = 26 },
		gentle = { tension = 120, friction = 14 },
		wobbly = { tension = 180, friction = 12 },
		stiff = { tension = 210, friction = 20 },
		slow = { tension = 280, friction = 60 },
		molasses = { tension = 280, friction = 120 },
	},

	linear = {
		default = { speed = 1 },
	},

	tween = {
		default = {
			time = 1,
			style = Enum.EasingStyle.Quad,
			direction = Enum.EasingDirection.Out,
			repeatCount = 0,
			reverses = false,
			delayTime = 0,
		},
	},
}

return config
