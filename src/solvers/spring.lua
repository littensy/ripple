local types = require(script.Parent.Parent.types)
local intermediate = require(script.Parent.Parent.utils.intermediate)

type SpringOptions = {
	damping: number?,
	frequency: number?,
	mass: number?,
	tension: number?,
	friction: number?,
	position: number?,
	velocity: number?,
	impulse: number?,
}

local EPSILON = 1e-5
local STEP = 1 -- milliseconds
local MAX_PASS = 100

local function configure(options: SpringOptions)
	local mass = options.mass or 1
	local tension = options.tension or 170
	local friction = options.friction or 26

	if options.frequency or options.damping then
		local frequency = options.frequency or 2
		local damping = options.damping or 1

		-- note: multiply frequency instead of dividing so that the
		-- spring's speed increases as frequency increases
		tension = ((2 * math.pi * frequency) ^ 2) * mass
		friction = (4 * math.pi * damping * mass) * frequency
	end

	return {
		mass = mass,
		tension = tension,
		friction = friction,
		position = options.position,
		velocity = options.velocity,
		impulse = options.impulse,
	}
end

local function spring(motionGoal: types.MotionGoal, options: SpringOptions?): types.MotionSolver
	local config = configure(options or {})
	local goals = intermediate.to(motionGoal)
	local mounting = true

	return function(key, state, deltaTime)
		local goal = intermediate.index(goals, key)

		if not goal then
			return
		end

		if mounting then
			mounting = false
			state.value = (config.position or state.value or 0)
			state.velocity = (config.velocity or state.velocity or 0) + (config.impulse or 0)
		end

		local position = state.value
		local velocity = state.velocity or 0
		local passes = math.min(math.ceil((deltaTime * 1000) / STEP), MAX_PASS)

		for _ = 1, passes do
			local springForce = -config.tension * 0.000001 * (position - goal)
			local dampingForce = -config.friction * 0.001 * velocity
			local acceleration = (springForce + dampingForce) / config.mass

			velocity += acceleration * STEP
			position += velocity * STEP
		end

		if math.abs(velocity) < EPSILON and math.abs(position - goal) < EPSILON then
			state.complete = true
			state.value = goal
			state.velocity = 0
		else
			state.value = position
			state.velocity = velocity
		end
	end
end

return spring
