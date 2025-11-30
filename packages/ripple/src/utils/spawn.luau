local freeThread: thread?

local function run<T...>(thread: thread, fn: (T...) -> (), ...: T...)
	freeThread = nil
	fn(...)
	freeThread = thread
end

local function runner()
	while true do
		run(coroutine.yield())
	end
end

local function spawn<T...>(callback: (T...) -> (), ...: T...)
	local thread = freeThread or task.spawn(runner)
	task.spawn(thread, thread, callback, ...)
end

local function call<T...>(callback: (T...) -> (), ...: T...)
	callback(...)
end

return (if task then spawn else call) :: typeof(spawn)
