-- spr-like API for animating instance and table properties using springs
-- https://github.com/fraktality/spr

local createSpring = require("./createSpring")
local spawn = require("./utils/spawn")
local types = require("./types")

type Animatable = types.Animatable
type Spring<T = any> = createSpring.Spring<T>
type SpringOptions<T = any> = createSpring.SpringOptions<T>

type AnimatableObject = {} | Instance

type AnimatableObjectState<T = any> = {
	springs: { [string]: Spring<T> },
	onComplete: { () -> () }?,
}

local objects: { [AnimatableObject]: AnimatableObjectState } = {}

local function assertPropertyType(object: AnimatableObject, property: string, newValue: any)
	local success, value = pcall(function()
		return (object :: any)[property]
	end)

	if not success then
		error(`Cannot animate property "{property}" on object "{object}"`, 2)
	elseif typeof(value) ~= typeof(newValue) then
		error(`Property "{property}" ({typeof(value)}) on object "{object}" cannot be set to {newValue}`)
	end
end

local function dispatchOnComplete(state: AnimatableObjectState)
	if state.onComplete then
		for _, callback in state.onComplete do
			spawn(callback)
		end
	end
end

local function createSpringForProperty(
	object: any,
	property: string,
	state: AnimatableObjectState,
	options: SpringOptions?
): Spring
	local spring = createSpring(object[property], options)

	spring:onChange(function(newValue)
		object[property] = newValue
	end)

	spring:onComplete(function()
		spring:stop()
		state.springs[property] = nil

		if not next(state.springs) then
			objects[object] = nil
			dispatchOnComplete(state)
		end
	end)

	spring:start()
	state.springs[property] = spring

	return spring
end

local function stop(object: AnimatableObject)
	local state = objects[object]

	if not state then
		return
	end

	for _, spring in state.springs do
		spring:stop()
	end

	objects[object] = nil
	dispatchOnComplete(state)
end

local function target(
	object: AnimatableObject,
	options: SpringOptions<Animatable>?,
	properties: { [string]: Animatable? }
)
	local state: AnimatableObjectState = objects[object] or { springs = {} }

	for property, value in properties do
		local spring = state.springs[property]

		assertPropertyType(object, property, value)

		if spring then
			spring:setGoal(value, options)
		else
			createSpringForProperty(object, property, state, options):setGoal(value)
		end
	end

	if next(state.springs) then
		objects[object] = state
	end
end

local function configure(object: AnimatableObject, options: SpringOptions<Animatable>, properties: { string }?)
	local state: AnimatableObjectState = objects[object] or { springs = {} }

	if not properties then
		for _, spring in state.springs do
			spring:configure(options)
		end
	else
		for _, property in properties do
			local spring = state.springs[property]

			if spring then
				spring:configure(options)
			elseif options.impulse or options.velocity then
				createSpringForProperty(object, property, state, options)
			end
		end

		if next(state.springs) then
			objects[object] = state
		end
	end
end

local function completed(object: AnimatableObject, callback: () -> ()): () -> ()
	local state: AnimatableObjectState = objects[object] or { springs = {} }

	if objects[object] then
		objects[object] = state
	end

	local listeners = state.onComplete or {}

	if not state.onComplete then
		state.onComplete = listeners
	end

	table.insert(listeners, callback)

	return function()
		-- Only mutate listeners if the object is animating
		if objects[object] == state then
			table.remove(listeners, table.find(listeners, callback) or 0)
		end
	end
end

return {
	objects = objects,
	target = target,
	stop = stop,
	configure = configure,
	completed = completed,
}
