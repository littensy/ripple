local RunService = game:GetService("RunService")

local types = require(script.Parent.types)
local immediateSolver = require(script.Parent.solvers.immediate)
local linearSolver = require(script.Parent.solvers.linear)
local springSolver = require(script.Parent.solvers.spring)
local tweenSolver = require(script.Parent.solvers.tween)
local intermediate = require(script.Parent.utils.intermediate)
local assign = require(script.Parent.utils.assign)
local merge = require(script.Parent.utils.merge)

local defaults = {
	heartbeat = RunService.Heartbeat,
	start = false,
}

local function createMotion<T>(initialValue: T, options: types.MotionOptions?): types.Motion<T>
	local config = merge(defaults, options or {})
	local valueType = typeof(initialValue)

	local motionState: { [any]: types.MotionState } = {}
	local motionSolvers: { [any]: types.MotionSolver } = {}

	local onStepListeners: { (value: T, deltaTime: number) -> () } = {}
	local onCompleteListeners: { (value: T) -> () } = {}
	local nextListenerId = 1

	local connection: RBXScriptConnection?
	local wasComplete = false
	local lastCompleteValue

	for key, value in intermediate.to(initialValue) do
		motionState[key] = {
			value = value,
			complete = true,
		}
	end

	local function stop()
		if connection then
			connection:Disconnect()
			connection = nil
		end
	end

	local function start(self)
		if connection then
			return stop
		end

		connection = config.heartbeat:Connect(function(deltaTime)
			self:step(deltaTime)
		end)

		return stop
	end

	local function get()
		local intermediates = {}

		for key, state in motionState do
			intermediates[key] = state.value
		end

		return intermediate.from(intermediates, valueType)
	end

	local function getVelocity()
		local intermediates = {}

		for key, state in motionState do
			intermediates[key] = state.velocity or 0
		end

		return intermediate.from(intermediates, valueType)
	end

	local function set(_self, value)
		local intermediates = intermediate.to(value)

		for key, state in motionState do
			local newValue = intermediates[key]

			if newValue then
				state.value = newValue
				state.complete = false
			end
		end
	end

	local function patch(_self, source)
		for key, state in motionState do
			local stateSource = source[key]

			if stateSource then
				state.complete = false
				assign(state, stateSource)
			end
		end
	end

	local function impulse(_self, impulses)
		if type(impulses) == "number" then
			for _, state in motionState do
				if not state.velocity then
					continue
				end

				state.complete = false
				state.velocity += impulses
			end

			return
		end

		local intermediateImpulses = intermediate.to(impulses)

		for key, amount in intermediateImpulses do
			local state = motionState[key]

			if not state or not state.velocity then
				continue
			end

			state.complete = false
			state.velocity += amount
		end
	end

	local function setVelocity(_self, velocity)
		local intermediates = intermediate.to(velocity)

		for key, amount in intermediates do
			local state = motionState[key]

			if not state or not state.velocity then
				continue
			end

			state.complete = false
			state.velocity = amount
		end
	end

	local function to(_self, solvers)
		if type(solvers) == "function" then
			for key, state in motionState do
				if state.destructor then
					state.destructor()
					state.destructor = nil
				end

				state.complete = false

				if solvers(key, state, 0) ~= false then
					-- only sets the solver if this key is part of the new goal
					motionSolvers[key] = solvers
				end
			end

			return
		end

		for key, solver in solvers do
			local state = motionState[key]

			if not state then
				continue
			end

			if state.destructor then
				state.destructor()
				state.destructor = nil
			end

			state.complete = false

			if solver(key, state, 0) ~= false then
				-- only sets the solver if this key is part of the new goal
				motionSolvers[key] = solver
			end
		end
	end

	local function immediate(self, value)
		self:to(immediateSolver(value :: any))
	end

	local function linear(self, value, params)
		self:to(linearSolver(value :: any, params))
	end

	local function spring(self, value, params)
		self:to(springSolver(value :: any, params))
	end

	local function tween(self, value, params)
		self:to(tweenSolver(value :: any, params))
	end

	local function step(self, deltaTime)
		for key, handler in motionSolvers do
			local state = motionState[key]

			if state and not state.complete then
				handler(key, state, deltaTime)
			end
		end

		local value = self:get()
		local complete = self:isComplete()

		if not complete or not wasComplete or lastCompleteValue ~= value then
			for _, listener in onStepListeners do
				task.spawn(listener, value, deltaTime)
			end
		end

		if complete and (not wasComplete or lastCompleteValue ~= value) then
			for _, listener in onCompleteListeners do
				task.spawn(listener, value)
			end
		end

		wasComplete = complete
		lastCompleteValue = value

		return value
	end

	local function isComplete()
		for _, state in motionState do
			if not state.complete then
				return false
			end
		end

		return true
	end

	local function onComplete(_self, callback)
		local listenerId = nextListenerId
		nextListenerId += 1
		onCompleteListeners[listenerId] = callback

		return function()
			onCompleteListeners[listenerId] = nil
		end
	end

	local function onStep(_self, callback)
		local listenerId = nextListenerId
		nextListenerId += 1
		onStepListeners[listenerId] = callback

		return function()
			onStepListeners[listenerId] = nil
		end
	end

	local function destroy()
		wasComplete = false
		nextListenerId = 1

		stop()

		table.clear(onStepListeners)
		table.clear(onCompleteListeners)
		table.clear(motionSolvers)

		for _, state in motionState do
			if state.destructor then
				state.destructor()
				state.destructor = nil
			end
		end
	end

	local motion: types.Motion<T> = {
		state = motionState,
		start = start,
		stop = stop,
		get = get,
		set = set,
		getVelocity = getVelocity,
		setVelocity = setVelocity,
		impulse = impulse,
		patch = patch,
		to = to,
		immediate = immediate,
		linear = linear,
		spring = spring,
		tween = tween,
		step = step,
		isComplete = isComplete,
		onComplete = onComplete,
		onStep = onStep,
		destroy = destroy,
	}

	if config.start then
		motion:start()
	end

	return motion
end

return createMotion
