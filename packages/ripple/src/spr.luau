-- spr-like API for animating instance and table properties using springs
-- https://github.com/fraktality/spr

local createSpring = require("./createSpring")
local spawn = require("./utils/spawn")
local types = require("./types")

type Animatable = types.Animatable
type Spring = createSpring.Spring<Animatable>
type SpringOptions = createSpring.SpringOptions<Animatable>

type AnimatableObject = {} | Instance
type SpringState = { [string]: Spring }

local springStates: { [AnimatableObject]: SpringState? } = {}
-- In cases where spr.completed is called on an object that is not animating,
-- ensure that the callbacks do not prevent garbage collection.
local completedCallbacks: { [AnimatableObject]: { () -> () }? } = setmetatable({} :: any, { __mode = "k" })

local function assertPropertyType(object: AnimatableObject, property: string, newValue: unknown)
	local success, value = pcall(function()
		return (object :: any)[property]
	end)

	if not success then
		error(`Cannot animate property "{property}" on object "{object}"`, 2)
	elseif typeof(value) ~= typeof(newValue) then
		error(`Property "{property}" ({typeof(value)}) on object "{object}" cannot be set to {newValue}`)
	end
end

local function dispose(object: AnimatableObject)
	springStates[object] = nil

	local callbacks = completedCallbacks[object]
	if callbacks then
		-- Remove the callback list before invoking callbacks to allow adding
		-- new callbacks without affecting the current invocation.
		completedCallbacks[object] = nil
		-- Removals are not performed at this point, so we can iterate safely.
		for _, callback in callbacks do
			spawn(callback)
		end
	end
end

local function createSpringForProperty(
	object: any,
	property: string,
	state: SpringState,
	options: SpringOptions?
): Spring
	local spring = createSpring(object[property], options)

	spring:onChange(function(newValue)
		object[property] = newValue
	end)

	spring:onComplete(function()
		spring:stop()
		state[property] = nil
		-- If this was the last spring to complete, remove the state and invoke
		-- any completion callbacks.
		if not next(state) then
			dispose(object)
		end
	end)

	spring:start()
	state[property] = spring

	return spring
end

local function stop(object: AnimatableObject)
	local state = springStates[object]

	if state then
		for _, spring in state do
			spring:stop()
		end

		dispose(object)
	end
end

local function target(object: AnimatableObject, options: SpringOptions?, properties: { [string]: Animatable? })
	local state: SpringState = springStates[object] or {}
	local velocityChanged = options and (options.impulse or options.velocity)

	for property, value in properties do
		local spring = state[property]

		assertPropertyType(object, property, value)

		if spring then
			spring:setGoal(value :: Animatable, options)
		elseif value ~= (object :: any)[property] or velocityChanged then
			-- Only create a new spring if the goal is different from the
			-- current value, or if an impulse or velocity is specified.
			createSpringForProperty(object, property, state, options):setGoal(value :: Animatable)
		end
	end

	if next(state) then
		springStates[object] = state
	end
end

local function update(object: AnimatableObject, options: SpringOptions, properties: { string })
	local state: SpringState = springStates[object] or {}
	local velocityChanged = options.impulse or options.velocity

	for _, property in properties do
		local spring = state[property]

		if spring then
			spring:configure(options)
		elseif velocityChanged then
			createSpringForProperty(object, property, state, options)
		end
	end

	if next(state) then
		springStates[object] = state
	end
end

local function completed(object: AnimatableObject, callback: () -> ()): () -> ()
	local callbacks = completedCallbacks[object] or {}

	if not completedCallbacks[object] then
		completedCallbacks[object] = callbacks
	end

	table.insert(callbacks, callback)

	return function()
		-- We can ignore removals if this callback list is not in use.
		if completedCallbacks[object] == callbacks then
			local index = table.find(callbacks, callback)
			if index then
				table.remove(callbacks, index)
			end
		end
	end
end

return {
	springStates = springStates,
	completedCallbacks = completedCallbacks,
	target = target,
	update = update,
	stop = stop,
	completed = completed,
}
