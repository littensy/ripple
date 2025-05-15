local spawn = require("./spawn")

export type Signal<T> = {
	connect: (T) -> () -> (),
	fire: T,
}

local function signal(): Signal<(...any) -> ()>
	local currentListeners: { (...any) -> () } = {}
	local nextListeners = currentListeners
	local nextListenerId = 0

	local function ensureCanMutateNextListeners()
		if nextListeners == currentListeners then
			nextListeners = table.clone(currentListeners)
		end
	end

	local function connect(callback: (...any) -> ()): () -> ()
		ensureCanMutateNextListeners()

		local listenerId = nextListenerId
		nextListenerId += 1
		nextListeners[listenerId] = callback

		return function()
			ensureCanMutateNextListeners()
			nextListeners[listenerId] = nil
		end
	end

	local function fire(...)
		currentListeners = nextListeners

		for _, listener in currentListeners do
			spawn(listener, ...)
		end
	end

	return {
		connect = connect,
		fire = fire,
	}
end

return signal
