local types = require(script.Parent.Parent.types)

local STEP = 1 / 50
local DURATION = 0.3
local WIDTH = 30

local function graph(label: string, solver: types.MotionSolver)
	local state: types.MotionState = { value = 0, complete = false }
	local output = ""

	for _ = 0, DURATION, STEP do
		output ..= `\n{string.format("%.2f", state.value)}: {string.rep(" ", math.round(state.value * WIDTH))}*`
		solver("value", state, STEP)
	end

	print(`📈 {label}{output}`)
end

return graph
