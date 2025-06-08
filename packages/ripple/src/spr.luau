-- spr-like API for animating instance and table properties using springs
-- https://github.com/fraktality/spr

local createSpring = require("./animation/createSpring")

type Spring<T = any> = createSpring.Spring<T>
type SpringOptions<T = any> = createSpring.SpringOptions<T>

type AnimatableObject<T = any> = { [string]: T } | Instance

type AnimatableObjectState<T = any> = {
	springs: { [string]: Spring<T>? },
	onComplete: { () -> () }?,
}

local objects: { [AnimatableObject]: AnimatableObjectState } = {}

local function assertPropertyType<T>(instance: AnimatableObject<T>, property: string, newValue: T)
	local success, value = pcall(function()
		return (instance :: any)[property]
	end)

	if not success then
		error(`Invalid property "{property}" on instance "{instance}"`, 2)
	elseif typeof(value) ~= typeof(newValue) then
		error(`Property "{property}" ({typeof(value)}) on instance "{instance}" cannot be set to {newValue}`)
	end
end

local function runOnCompleteListeners(state: AnimatableObjectState)
	if state.onComplete then
		for _, callback in state.onComplete do
			callback()
		end
	end
end

local function createSpringForProperty<T>(
	instance: any,
	property: string,
	state: AnimatableObjectState<T>,
	options: SpringOptions<T>?
): Spring<T>
	local spring = createSpring(instance[property], options)

	spring:onChange(function(newValue)
		instance[property] = newValue
	end)

	spring:onComplete(function()
		state.springs[property] = nil

		if not next(state.springs) then
			objects[instance] = nil
			runOnCompleteListeners(state)
		end
	end)

	spring:start()

	state.springs[property] = spring

	return spring
end

local function stop<T>(instance: AnimatableObject<T>)
	local state = objects[instance]

	if not state then
		return
	end

	for _, spring in state.springs :: { [string]: Spring<T> } do
		spring:stop()
	end

	objects[instance] = nil
	runOnCompleteListeners(state)
end

local function target<T>(instance: AnimatableObject<T>, options: SpringOptions<T>?, properties: { [string]: T })
	local state: AnimatableObjectState = objects[instance] or { springs = {} }

	for property, value in properties do
		assertPropertyType(instance, property, value)

		if state[property] then
			state[property]:setGoal(value, options)
		else
			createSpringForProperty(instance, property, state, options):setGoal(value)
		end
	end

	if next(state.springs) then
		objects[instance] = state
	end
end

local function configure<T>(
	instance: AnimatableObject<T>,
	instanceOptions: SpringOptions<T>?,
	propertyOptions: { [string]: SpringOptions<T>? }?
)
	local state: AnimatableObjectState = objects[instance] or { springs = {} }

	if instanceOptions then
		for property, spring in state.springs :: { [string]: Spring<T> } do
			if not propertyOptions or not propertyOptions[property] then
				spring:configure(instanceOptions)
			end
		end
	end

	if propertyOptions then
		for property, options in propertyOptions do
			if state[property] then
				state[property]:configure(options)
			else
				createSpringForProperty(instance, property, state, options)
			end
		end
	end

	if next(state.springs) then
		objects[instance] = state
	end
end

local function completed(instance: AnimatableObject, callback: () -> ()): () -> ()
	local state = objects[instance]

	if not state then
		return function() end
	end

	local listeners = state.onComplete or {}

	if not state.onComplete then
		state.onComplete = listeners
	end

	table.insert(listeners, callback)

	return function()
		-- Do not mutate listeners if the callback is currently running
		if objects[instance] == state then
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
