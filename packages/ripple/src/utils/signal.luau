local spawn = require("./spawn")

export type FireSignal<T...> = (T...) -> ()
export type SubscribeSignal<T...> = (callback: FireSignal<T...>) -> () -> ()

local function signal<T...>(): (SubscribeSignal<T...>, FireSignal<T...>)
	local listeners: { (...any) -> () } = {}
	local count = 0

	local function subscribe(callback: (T...) -> ()): () -> ()
		table.insert(listeners, callback)
		count += 1

		return function()
			local index = table.find(listeners, callback)

			if index then
				listeners[index] = listeners[count]
				listeners[count] = nil
				count -= 1
			end
		end
	end

	local function fire(...: T...)
		for index = count, 1, -1 do
			spawn(listeners[index], ...)
		end
	end

	return subscribe, fire
end

return signal
