local createSpring = require(script.Parent.createSpring)

local spring = createSpring(0, {
	tension = 170,
	friction = 26,
	start = true,
})

spring:position(1)
spring:velocity(-1)
spring:to(0, { tension = 180 })

spring:onStep(function(value, dt)
	print(value, dt)
end)
