--!native
--!optimize 2

local convert = require(script.Parent.utils.convert)
type Animatable = convert.Animatable
type Components = convert.Components
local heartbeat = require(script.Parent.utils.heartbeat)
local signal = require(script.Parent.utils.signal)
type Signal<T...> = signal.Signal<T...>

export type SpringConfig<T> = {
	start: boolean?,
	mass: number?,
	tension: number?,
	friction: number?,
	position: T?,
	velocity: T?,
	impulse: T?,
	frequency: number?,
	damping: number?,
	precision: number?,
	restVelocity: number?,
}

type SpringConfigInternal = {
	mass: number,
	tension: number,
	friction: number,
	restPosition: number,
	restVelocity: number,
}

export type Spring<T> = {
	position: T,
	velocity: T,
	goal: T,
	complete: boolean,
	impulse: (self: SpringInternal<T>, amount: T) -> (),
	to: (self: SpringInternal<T>, goal: T, config: SpringConfig<T>?) -> (),
	configure: (self: SpringInternal<T>, config: SpringConfig<T>) -> (),
	step: (self: SpringInternal<T>, deltaTime: number) -> T,
	onComplete: (self: SpringInternal<T>, callback: (value: T) -> ()) -> () -> (),
	onStep: (self: SpringInternal<T>, callback: (value: T, deltaTime: number) -> ()) -> () -> (),
	start: (self: SpringInternal<T>) -> () -> (),
	stop: (self: SpringInternal<T>) -> (),
	destroy: (self: SpringInternal<T>) -> (),
}

type SpringInternal<T> = Spring<T> & {
	_config: SpringConfigInternal,
	_kind: string,

	_position: Components,
	_velocity: Components,
	_goal: Components,

	_running: boolean,
	_sleeping: boolean,

	_onComplete: Signal<T>,
	_onStep: Signal<(T, number)>,

	_step: (deltaTime: number) -> T,
	_wake: (self: SpringInternal<T>) -> (),
	_sleep: (self: SpringInternal<T>) -> (),

	__index: (self: SpringInternal<T>, key: string) -> any,
	__newindex: (self: SpringInternal<T>, key: string, value: any) -> (),
}

local Spring = {} :: SpringInternal<Animatable>

local function applyConfig<T>(target: SpringConfigInternal, source: SpringConfig<T>): SpringConfigInternal
	target.mass = source.mass or target.mass
	target.restPosition = source.precision or target.restPosition
	target.restVelocity = source.restVelocity or target.restVelocity

	if source.damping or source.frequency then
		local frequency = source.frequency or 0.5
		local damping = source.damping or 1

		target.tension = (2 * math.pi / frequency) ^ 2 * target.mass
		target.friction = (4 * math.pi * damping * target.mass) / frequency
	else
		target.tension = source.tension or target.tension
		target.friction = source.friction or target.friction
	end

	return target
end

local function createSpring(initial: Animatable, config: SpringConfig<Animatable>?): Spring<Animatable>
	local self: SpringInternal<Animatable> = setmetatable({} :: any, Spring)

	self._config = applyConfig({
		mass = 1,
		tension = 170,
		friction = 26,
		restPosition = 0.001,
		restVelocity = 0.001,
	}, config or {})

	self._kind = typeof(initial)

	self._position = convert.toComponents(initial, self._kind)
	self._velocity = convert.toZeros(self._position)
	self._goal = table.clone(self._position)

	self._running = false
	self._sleeping = true

	self._onComplete = signal.create()
	self._onStep = signal.create()

	function self._step(deltaTime: number)
		if self._sleeping then
			return convert.fromComponents(self._position, self._kind)
		end

		local tension = self._config.tension
		local friction = self._config.friction
		local mass = self._config.mass

		local restPosition = self._config.restPosition
		local restVelocity = self._config.restVelocity
		local restPositionVector = vector.one * restPosition
		local restVelocityVector = vector.one * restVelocity

		-- Compute springs every millisecond
		local passes = math.min(math.ceil(deltaTime * 1000), 128)
		local done = true

		-- Move each component towards its goal using a spring model. Sets the
		-- `done` flag to `false` if any component is outside the rest position
		-- and velocity thresholds.
		for index, position in self._position do
			local goal = self._goal[index] :: any
			local velocity = self._velocity[index] :: any

			-- https://github.com/pmndrs/react-spring/blob/main/packages/core/src/SpringValue.ts#L278
			for _ = 1, passes do
				local springForce = -0.000001 * tension * (position - goal)
				local dampingForce = -0.001 * friction * velocity
				local acceleration = (springForce + dampingForce) / mass

				velocity += acceleration
				position += velocity
			end

			self._position[index] = position
			self._velocity[index] = velocity

			if not done then
				continue
			end

			if type(position) == "vector" then
				-- Check if the vector is within a certain threshold of the
				-- goal by comparing each component with vector.max.
				done = vector.max(vector.abs(position - goal), restPositionVector) == restPositionVector
					and vector.max(vector.abs(velocity), restVelocityVector) == restVelocityVector
			else
				done = math.abs(position - goal) <= restPosition and math.abs(velocity) <= restVelocity
			end
		end

		local result = convert.fromComponents(self._position, self._kind)

		-- Once all components are within the rest position and velocity, the
		-- animation is complete and we should snap to the goal.
		if done then
			if not self._sleeping then
				self._position = self._goal
				self._velocity = convert.toZeros(self._position)

				self:_sleep()
				self._onStep.fire(result, deltaTime)
				self._onComplete.fire(result)
			end

			return result
		end

		self._onStep.fire(result, deltaTime)

		return result
	end

	if config and config.start then
		self:start()
	end

	return self
end

function Spring:_wake()
	self._sleeping = false

	if self._running then
		heartbeat.connect(self._step)
	end
end

function Spring:_sleep()
	self._sleeping = true
	heartbeat.disconnect(self._step)
end

function Spring:to(value, config)
	if config then
		self:configure(config)
	end

	self._goal = convert.toComponents(value, self._kind)
	self:_wake()
end

function Spring:impulse(amount)
	for index, component in convert.toComponents(amount, self._kind) do
		self._velocity[index] += component :: any
	end

	self:_wake()
end

function Spring:configure(config)
	applyConfig(self._config, config)

	if config.position then
		self.position = config.position
	end

	if config.velocity then
		self.velocity = config.velocity
	end

	if config.impulse then
		self:impulse(config.impulse)
	end
end

function Spring:step(deltaTime)
	return self._step(deltaTime)
end

function Spring:onComplete(callback)
	return self._onComplete.connect(callback)
end

function Spring:onStep(callback)
	return self._onStep.connect(callback)
end

function Spring:start()
	self._running = true
	self:_wake()

	return function()
		self:stop()
	end
end

function Spring:stop()
	self._running = false
	self:_sleep()
end

function Spring:destroy()
	self:stop()
end

function Spring:__index(key)
	if key == "position" then
		return convert.fromComponents(self._position, self._kind)
	elseif key == "velocity" then
		return convert.fromComponents(self._velocity, self._kind)
	elseif key == "goal" then
		return convert.fromComponents(self._goal, self._kind)
	elseif key == "complete" then
		return self._sleeping
	else
		return Spring[key]
	end
end

function Spring:__newindex(key, value)
	if key == "position" then
		self._position = convert.toComponents(value, self._kind)
		self:_wake()
	elseif key == "velocity" then
		self._velocity = convert.toComponents(value, self._kind)
		self:_wake()
	elseif key == "goal" then
		self._goal = convert.toComponents(value, self._kind)
		self:_wake()
	else
		self[key] = value
	end
end

return createSpring :: <T>(initial: T & Animatable, config: SpringConfig<T>?) -> Spring<T>
