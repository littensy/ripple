local freeThread: thread?

local function run<T...>(thread: thread, fn: (T...) -> (), ...: T...): boolean
	freeThread = nil
	fn(...)
	if freeThread then
		return false
	else
		freeThread = thread
		return true
	end
end

local function runner()
	while run(coroutine.yield()) do
		continue
	end
end

local function spawn<T...>(callback: (T...) -> (), ...: T...)
	if not task then
		return callback(...)
	end

	local thread = freeThread or task.spawn(runner)

	coroutine.resume(thread, thread, callback, ...)
end

return spawn
