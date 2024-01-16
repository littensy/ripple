local types = require(script.Parent.Parent.types)
local config = require(script.Parent.Parent.config)
local intermediate = require(script.Parent.Parent.utils.intermediate)

local STEP = 1 -- milliseconds
local MAX_PASS = 100

local function configure(options: types.SpringOptions)
	local mass = options.mass or 1
	local tension = options.tension or config.spring.default.tension
	local friction = options.friction or config.spring.default.friction

	if options.frequency or options.damping then
		local frequency = options.frequency or 0.5
		local damping = options.damping or 1
		tension = (2 * math.pi / frequency) ^ 2 * mass
		friction = (4 * math.pi * damping * mass) / frequency
	end

	return {
		mass = mass,
		tension = tension,
		friction = friction,
		position = options.position,
		velocity = options.velocity,
		impulse = options.impulse,
		restingVelocity = options.restingVelocity or 0.001,
		restingPosition = options.restingPosition or 0.0001,
	}
end

local function spring(motionGoal: types.MotionGoal, options: types.SpringOptions?): types.MotionSolver
	local props = configure(options or {})
	local goals = intermediate.to(motionGoal)
	local mounting = true

	return function(key, state, deltaTime)
		local goal = intermediate.index(goals, key)

		if not goal then
			return false
		end

		if mounting then
			mounting = false
			state.value = (props.position or state.value or 0)
			state.velocity = (props.velocity or state.velocity or 0) + (props.impulse or 0)
		end

		local position = state.value
		local velocity = state.velocity or 0
		local passes = math.min(math.ceil((deltaTime * 1000) / STEP), MAX_PASS)

		for _ = 1, passes do
			local springForce = -props.tension * 0.000001 * (position - goal)
			local dampingForce = -props.friction * 0.001 * velocity
			local acceleration = (springForce + dampingForce) / props.mass

			velocity += acceleration * STEP
			position += velocity * STEP
		end

		if math.abs(velocity) < props.restingVelocity and math.abs(position - goal) < props.restingPosition then
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
