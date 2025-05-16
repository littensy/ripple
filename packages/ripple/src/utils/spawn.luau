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
	if not task then
		return callback(...)
	end

	local thread = freeThread or task.spawn(runner)

	task.spawn(thread, thread, callback, ...)
end

return spawn
