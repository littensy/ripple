type Spy = {
	calls: number,
	arguments: { { unknown } },
	handle: (...any) -> (),
}

local function spy(): Spy
	local self: Spy

	local function handle(...)
		self.calls += 1
		self.arguments[self.calls] = { ... }
	end

	self = {
		calls = 0,
		arguments = {},
		handle = handle,
	}

	return self
end

return spy
