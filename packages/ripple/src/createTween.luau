local TweenService = game:GetService("TweenService")

local assign = require(script.Parent.utils.assign)
local signal = require(script.Parent.utils.signal)

export type EasingStyle =
	Enum.EasingStyle
	| "Linear"
	| "Sine"
	| "Back"
	| "Quad"
	| "Quart"
	| "Quint"
	| "Bounce"
	| "Elastic"
	| "Exponential"
	| "Circular"
	| "Cubic"

export type EasingDirection = Enum.EasingDirection | "In" | "Out" | "InOut"

export type TweenConfig<T> = {
	position: T?,
	duration: number?,
	easing: EasingStyle?,
	direction: EasingDirection?,
	repeatCount: number?,
	reverses: boolean?,
	delay: number?,
}

export type Tweened<T> = {
	-- TODO: Add __index metamethods for position and goal
	position: (self: Tweened<T>, value: T?) -> T,
	to: (self: Tweened<T>, goal: T, config: TweenConfig<T>?) -> (),
	isComplete: (self: Tweened<T>) -> boolean,
	onComplete: (self: Tweened<T>, callback: (value: T) -> ()) -> () -> (),
	onStep: (self: Tweened<T>, callback: (value: T) -> ()) -> () -> (),
	pause: (self: Tweened<T>) -> (),
	resume: (self: Tweened<T>) -> (),
	destroy: (self: Tweened<T>) -> (),
}

type ContainerInfo = {
	class: string,
	property: string,
}

local toContainer: { [string]: ContainerInfo } = {
	number = { class = "NumberValue", property = "Value" },
	Vector2 = { class = "Vector2Value", property = "Value" },
	Vector3 = { class = "Vector3Value", property = "Value" },
	Color3 = { class = "Color3Value", property = "Value" },
	UDim = { class = "UICorner", property = "CornerRadius" },
	UDim2 = { class = "Frame", property = "Position" },
	CFrame = { class = "CFrameValue", property = "Value" },
	Rect = { class = "ImageLabel", property = "ImageRectOffset" },
}

local function castEnum(enum: Enum, value: unknown)
	return type(value) == "string" and (enum :: any)[value] or value
end

local function createContainer<T>(value: T)
	local container = toContainer[typeof(value)]

	if not container then
		error(`Cannot create tween for unsupported type {typeof(value)}`)
	end

	local object: { [string]: any } = Instance.new(container.class) :: any

	object[container.property] = value

	return object, container.property
end

local function createTween<T>(initial: T, config: TweenConfig<T>?): Tweened<T>
	local self = {} :: Tweened<T>

	local params: TweenConfig<T> = assign({
		duration = 0.5,
		easing = Enum.EasingStyle.Quad,
		direction = Enum.EasingDirection.Out,
	}, config or {})

	-- TODO: Test if the container can be garbage collected
	local container, property = createContainer(initial)
	local goal = initial
	local paused = false

	local tween: Tween?
	local completedConnection: RBXScriptConnection?
	local propertyConnection: RBXScriptConnection?

	local onComplete = signal.create()
	local onStep = signal.create()

	local function connectToProperty()
		if propertyConnection then
			return
		end

		propertyConnection = container:GetPropertyChangedSignal(property):Connect(function()
			onStep.fire(container[property])
		end)
	end

	local function disconnectFromProperty()
		if propertyConnection then
			propertyConnection:Disconnect()
			propertyConnection = nil
		end
	end

	local function createTween()
		if completedConnection then
			completedConnection:Disconnect()
		end

		if tween then
			tween:Cancel()
		end

		local tweenInfo = TweenInfo.new(
			params.duration,
			castEnum(Enum.EasingStyle, params.easing),
			castEnum(Enum.EasingDirection, params.direction),
			params.repeatCount,
			params.reverses,
			params.delay
		)

		local nextTween = TweenService:Create(container, tweenInfo, {
			[property] = goal,
		})

		completedConnection = nextTween.Completed:Once(function()
			disconnectFromProperty()
			onComplete.fire(goal)
		end)

		if not paused then
			connectToProperty()
			nextTween:Play()
		end

		tween = nextTween
	end

	function self:position(value)
		if value then
			container[property] = value
			createTween()
		end

		return container[property]
	end

	function self:to(target, config)
		if config then
			assign(params, config)
		end

		goal = target
		createTween()
	end

	function self:isComplete()
		return not tween or tween.PlaybackState == Enum.PlaybackState.Completed
	end

	function self:onComplete(callback)
		return onComplete.connect(callback)
	end

	function self:onStep(callback)
		return onStep.connect(callback)
	end

	function self:pause()
		if tween then
			tween:Pause()
		end

		paused = true
		disconnectFromProperty()
	end

	function self:resume()
		if tween then
			tween:Play()
		end

		paused = false
		connectToProperty()
	end

	function self:destroy()
		disconnectFromProperty()

		if completedConnection then
			completedConnection:Disconnect()
			completedConnection = nil
		end

		if tween then
			tween:Cancel()
			tween = nil
		end

		container:Destroy()
	end

	return self
end

return createTween
