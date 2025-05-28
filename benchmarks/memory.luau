local createGroupMotor = require("./otter/createGroupMotor")
local createSpring = require("../packages/ripple/src/animation/createSpring")

local _refs: { any } = {}
local start = gcinfo()

for _ = 1, 1000 do
	table.insert(_refs, createSpring(0))
end

print(`Ripple memory used: {(gcinfo() - start)} KB`)

start = gcinfo()

for _ = 1, 1000 do
	table.insert(_refs, createGroupMotor({ x = 0 }))
end

print(`Otter memory used: {(gcinfo() - start)} KB`)
