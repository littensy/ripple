export type Signal<T...> = {
	fire: (T...) -> (),
	connect: ((T...) -> ()) -> () -> (),
}

local function create<T...>(): Signal<T...>
	local listeners: { [(...any) -> ()]: true } = {}

	local function fire(...: T...)
		for listener in listeners do
			task.spawn(listener, ...)
		end
	end

	local function connect(listener: (T...) -> ()): () -> ()
		listeners[listener] = true

		return function()
			listeners[listener] = nil
		end
	end

	return {
		fire = fire,
		connect = connect,
	}
end

return {
	create = create,
}
