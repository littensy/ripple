local SpringValue = require("./react-flow/SpringValue")
local createSingleMotor = require("./otter/createSingleMotor")
local createSpring = require("../packages/ripple/src/animation/createSpring")
local otterSpring = require("./otter/spring")

local references: { [any]: true? } = {}
local start = gcinfo()

for _ = 1, 100 do
	local spring = createSpring(0)
	spring:setGoal(1)
	spring:start()
	references[spring] = true
end

print(`Ripple memory used: {(gcinfo() - start)} KB`)

start = gcinfo()

for _ = 1, 100 do
	local motor = createSingleMotor(0)
	motor:setGoal(otterSpring(1))
	motor:start()
	references[motor] = true
end

print(`Otter memory used: {(gcinfo() - start)} KB`)

start = gcinfo()

for _ = 1, 100 do
	local spring = SpringValue.new(0)
	spring:SetGoal(1)
	spring:Run(function() end)
	references[spring] = true
end

print(`React Flow memory used: {(gcinfo() - start)} KB`)
