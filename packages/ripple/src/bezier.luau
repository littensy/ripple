local interpolate = require("./utils/interpolate")
local scheduler = require("./utils/scheduler")
local signal = require("./utils/signal")
local types = require("./types")

type Animatable = types.Animatable

export type BezierState<Value = any> = {
	position: Value,
	points: { Value },
	from: Value,
	goal: Value,
	duration: number,
	elapsed: number,
	started: boolean,
	complete: boolean,
	onChange: signal.SubscribeSignal<(Value, number)>,
	fireChange: signal.FireSignal<(Value, number)>,
	onComplete: signal.SubscribeSignal<Value>,
	fireComplete: signal.FireSignal<Value>,
}

export type BezierOptions<Value = any> = {
	start: boolean?,
	duration: number?,
	points: { Value },
}

export type Bezier<Value = any> = {
	state: BezierState<Value>,

	setPosition: (self: Bezier<Value>, value: Value) -> (),
	setPoints: (self: Bezier<Value>, points: { Value }) -> (),

	getPosition: (self: Bezier<Value>) -> Value,
	getFrom: (self: Bezier<Value>) -> Value,

	onChange: (self: Bezier<Value>, callback: (value: Value, deltaTime: number) -> ()) -> () -> (),
	onComplete: (self: Bezier<Value>, callback: (value: Value) -> ()) -> () -> (),

	step: (self: Bezier<Value>, deltaTime: number) -> Value,
	idle: (self: Bezier<Value>) -> boolean,
	configure: (self: Bezier<Value>, options: BezierOptions<Value>) -> (),

	start: (self: Bezier<Value>) -> (),
	stop: (self: Bezier<Value>) -> (),
	destroy: (self: Bezier<Value>) -> (),

	resumeFromCurrentPosition: (self: Bezier<Value>) -> (),
}

local Bezier = {}
Bezier.__index = Bezier

local function getPointAtT<Value>(points: { Value }, t: number): Value
	assert(#points >= 2, "Bezier requires at least 2 points.")
	local working = table.clone(points)

	while #working > 1 do
		local nextLevel = {}
		for i = 1, #working - 1 do
			nextLevel[i] = interpolate(working[i], working[i + 1], t)
		end
		working = nextLevel
	end

	return working[1]
end

local bezierScheduler = scheduler("Bezier", function<T>(state: BezierState<T>, dt, remove)
	if state.complete then
		remove(state)
		return state.position
	end

	state.elapsed += dt
	local alpha = math.clamp(state.elapsed / state.duration, 0, 1)
	local value = getPointAtT(state.points, alpha)
	state.fireChange(value, alpha)
	state.position = value

	if alpha >= 1 then
		remove(state)
		state.complete = true
		state.fireComplete(value)
	end

	return value
end)

local function createBezier<Value>(initialPoints: { Value }, inputOptions: BezierOptions<Value>?)
	local options: BezierOptions<Value> = inputOptions or {}
	local position = options.points and options.points[1] or initialPoints[1]

	local onChange, fireChange = signal()
	local onComplete, fireComplete = signal()

	local state: BezierState<Value> = {
		position = position,
		points = nil,
		from = position,
		goal = position,
		duration = 1,
		elapsed = 0,
		started = false,
		complete = true,
		onChange = onChange,
		fireChange = fireChange,
		onComplete = onComplete,
		fireComplete = fireComplete,
	}

	local self: Bezier<Value> = setmetatable({
		state = state,
	}, Bezier) :: any

	self:setPoints(options.points or initialPoints)
	self:configure(options)

	if options.start then
		self:start()
	end

	return self
end

function Bezier:resumeFromCurrentPosition()
	local state = self.state

	state.complete = false
	state.elapsed = 0
	state.from = state.position

	if state.started then
		bezierScheduler.add(state)
	end
end

function Bezier:start()
	self.state.started = true

	if not self.state.complete then
		bezierScheduler.add(self.state)
	end
end

function Bezier:stop()
	self.state.started = false
	bezierScheduler.remove(self.state)
end

function Bezier:idle(): boolean
	return self.state.complete
end

function Bezier:step(dt: number): Animatable
	return bezierScheduler.update(self.state, dt)
end

function Bezier:configure(options: BezierOptions)
	local state = self.state

	state.duration = options.duration or state.duration

	if options.points then
		self:setPoints(options.points)
	end

	if not state.complete and state.elapsed ~= 0 then
		self:resumeFromCurrentPosition()
	end
end

function Bezier:getPosition(): Animatable
	return self.state.position
end

function Bezier:getFrom(): Animatable
	return self.state.from
end

function Bezier:getGoal(): Animatable
	return self.state.goal
end

function Bezier:setPoints<Value>(points: { Value })
	if self.state.points ~= points then
		self.state.points = points
		self:resumeFromCurrentPosition()
		self.state.fireChange(points[1], 0)
		self.state.goal = points[#points]
	end
end

function Bezier:onChange(callback: (value: Animatable, deltaTime: number) -> ()): () -> ()
	return self.state.onChange(callback)
end

function Bezier:onComplete(callback: (value: Animatable) -> ()): () -> ()
	return self.state.onComplete(callback)
end

function Bezier:destroy()
	self:stop()
end

return {
	scheduler = bezierScheduler,
	createBezier = createBezier,
}
