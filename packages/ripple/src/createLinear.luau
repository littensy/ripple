--!native
--!optimize 2

local convert = require(script.Parent.utils.convert)
type Animatable = convert.Animatable
local heartbeat = require(script.Parent.utils.heartbeat)
local signal = require(script.Parent.utils.signal)

export type LinearConfig<T> = {
	start: boolean?,
	speed: number?,
	position: T?,
}

export type Linear<T> = {
	-- TODO: Add __index metamethods for position and goal
	position: (self: Linear<T>, value: T?) -> T,
	to: (self: Linear<T>, goal: T, config: LinearConfig<T>?) -> (),
	configure: (self: Linear<T>, config: LinearConfig<T>) -> (),
	step: (self: Linear<T>, deltaTime: number) -> T,
	isComplete: (self: Linear<T>) -> boolean,
	onComplete: (self: Linear<T>, callback: (value: T) -> ()) -> () -> (),
	onStep: (self: Linear<T>, callback: (value: T, deltaTime: number) -> ()) -> () -> (),
	start: (self: Linear<T>) -> () -> (),
	stop: (self: Linear<T>) -> (),
	destroy: (self: Linear<T>) -> (),
}

local function createLinear(initial: Animatable, config: LinearConfig<Animatable>?): Linear<Animatable>
	local self = {} :: Linear<Animatable>

	local speed = config and config.speed or 1
	local kind = typeof(initial)

	local position = convert.toComponents(initial, kind)
	local goal = table.clone(position)

	local running = config and config.start
	local sleeping = true
	local sleep

	local onComplete = signal.create()
	local onStep = signal.create()

	local function step(deltaTime: number)
		if sleeping then
			return convert.fromComponents(position, kind)
		end

		local amount = deltaTime * speed
		local amountVector = vector.one * amount
		local done = true

		-- Move each component towards its goal by at most `amount` units. Sets
		-- the `done` flag to `false` if any component is not at its goal yet.
		for index, pos in position do
			local goal = goal[index] :: any

			if pos == goal then
				continue
			end

			if type(pos) == "vector" then
				-- Check if the vector is within `amount` units of the goal by
				-- performing a fast fuzzy equality check.
				if vector.max(vector.abs(pos - goal), amountVector) == amountVector then
					pos = goal
				else
					pos += (goal - pos).Unit * amount
					done = false
				end
			elseif math.abs(pos - goal) <= amount then
				pos = goal
			else
				pos += math.sign(goal - pos) * amount
				done = false
			end

			position[index] = pos
		end

		local result = convert.fromComponents(position, kind)

		if done then
			if not sleeping then
				sleep()
				onStep.fire(result, deltaTime)
				onComplete.fire(result)
			end

			return result
		end

		onStep.fire(result, deltaTime)

		return result
	end

	local function wake()
		sleeping = false

		if running then
			heartbeat.connect(step)
		end
	end

	function sleep()
		sleeping = true
		heartbeat.disconnect(step)
	end

	function self:position(value)
		if value then
			position = convert.toComponents(value, kind)
			wake()
		end

		return convert.fromComponents(position, kind)
	end

	function self:to(value, config)
		if config then
			self:configure(config)
		end

		goal = convert.toComponents(value, kind)
		wake()
	end

	function self:configure(config)
		speed = config.speed or speed

		if config.position then
			self:position(config.position)
		end
	end

	function self:step(deltaTime)
		return step(deltaTime)
	end

	function self:isComplete()
		return sleeping
	end

	function self:onComplete(callback)
		return onComplete.connect(callback)
	end

	function self:onStep(callback)
		return onStep.connect(callback)
	end

	function self:start()
		running = true
		wake()
		return function()
			self:stop()
		end
	end

	function self:stop()
		running = false
		sleep()
	end

	function self:destroy()
		self:stop()
	end

	return self
end

return createLinear :: <T>(initial: T & Animatable, config: LinearConfig<T>?) -> Linear<T>
