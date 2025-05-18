local spawn = require("./spawn")

export type FireSignal<T...> = (T...) -> ()
export type SubscribeSignal<T...> = (callback: FireSignal<T...>) -> () -> ()

local function signal<T...>(): (SubscribeSignal<T...>, FireSignal<T...>)
	local currentListeners: { (...any) -> () } = {}
	local nextListeners = currentListeners
	local nextListenerId = 0

	local function ensureCanMutateNextListeners()
		if nextListeners == currentListeners then
			nextListeners = table.clone(currentListeners)
		end
	end

	local function subscribe(callback: (T...) -> ()): () -> ()
		ensureCanMutateNextListeners()

		local listenerId = nextListenerId
		nextListenerId += 1
		nextListeners[listenerId] = callback

		return function()
			ensureCanMutateNextListeners()
			nextListeners[listenerId] = nil
		end
	end

	local function fire(...: T...)
		currentListeners = nextListeners

		for _, listener in currentListeners do
			spawn(listener, ...)
		end
	end

	return subscribe, fire
end

return signal
