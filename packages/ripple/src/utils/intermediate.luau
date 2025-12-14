local merge = require("./merge")
local oklab = require("./oklab")

export type Components = { number | vector | Vector3 }

export type Intermediate<T = any> = {
	components: Components,
	value: T,
	dirty: boolean?,
	encode: (components: Components, value: T) -> (),
	decode: (components: Components) -> T,
}

local encoders: { [string]: (Components, any) -> () } = {
	number = function(components: Components, value: number)
		components[1] = value
	end,
	vector = function(components: Components, value: vector)
		components[1] = value
	end,
	Vector3 = function(components: Components, value: Vector3)
		components[1] = value
	end,
	table = function(components: Components, value: { [any]: any })
		for k, v in value do
			components[k] = v
		end
	end,
	Vector2 = function(components: Components, value: Vector2)
		components[1] = vector.create(value.X, value.Y, 0)
	end,
	CFrame = function(components: Components, value: CFrame)
		components[1] = value.Position
		components[2] = value.XVector
		components[3] = value.YVector
		components[4] = value.ZVector
	end,
	Color3 = function(components: Components, value: Color3)
		components[1] = oklab.fromSRGB(vector.create(value.R, value.G, value.B))
	end,
	UDim = function(components: Components, value: UDim)
		components[1] = vector.create(value.Scale, value.Offset, 0)
	end,
	UDim2 = function(components: Components, value: UDim2)
		components[1] = vector.create(value.X.Scale, value.X.Offset, value.Y.Scale)
		components[2] = value.Y.Offset
	end,
	Rect = function(components: Components, value: Rect)
		components[1] = vector.create(value.Min.X, value.Min.Y, value.Max.X)
		components[2] = value.Max.Y
	end,
}

local decoders: { [string]: (components: { any }) -> any } = {
	number = function(components: { number }): number
		return components[1]
	end,
	vector = function(components: { vector }): vector
		return components[1]
	end,
	Vector3 = function(components: { Vector3 }): Vector3
		return components[1]
	end,
	table = function(components: Components): Components
		return table.clone(components)
	end,
	Vector2 = function(components: { vector }): Vector2
		local xy = components[1]
		return Vector2.new(xy.x, xy.y)
	end,
	CFrame = function(components: { Vector3 }): CFrame
		return CFrame.fromMatrix(components[1], components[2], components[3], components[4]):Orthonormalize()
	end,
	Color3 = function(components: { vector }): Color3
		local rgb = vector.max(oklab.toSRGB(components[1]), vector.zero)
		return Color3.new(rgb.x, rgb.y, rgb.z)
	end,
	UDim = function(components: { vector }): UDim
		local so = components[1]
		return UDim.new(so.x, math.round(so.y))
	end,
	UDim2 = function(components: { vector | number }): UDim2
		local abc = components[1] :: vector
		local d = components[2] :: number
		return UDim2.new(abc.x, math.round(abc.y), abc.z, math.round(d))
	end,
	Rect = function(components: { vector | number }): Rect
		local abc = components[1] :: vector
		local d = components[2] :: number
		return Rect.new(abc.x, abc.y, abc.z, d)
	end,
}

local function create<T>(value: T): Intermediate<T>
	local kind = typeof(value)
	local components: Components = {}
	local encode = encoders[kind]
	local decode = decoders[kind]

	if not encode or not decode then
		error(`Unsupported type {kind} for Ripple animation value`)
	end

	encode(components, value)

	return {
		components = components,
		value = value,
		encode = encode,
		decode = decode,
	}
end

local function copy<T>(intermediate: Intermediate<T>): Intermediate<T>
	return {
		components = table.clone(intermediate.components),
		value = intermediate.value,
		encode = intermediate.encode,
		decode = intermediate.decode,
	}
end

local function zero<T>(intermediate: Intermediate<T>): Intermediate<T>
	local components = intermediate.components

	for key in components do
		components[key] *= 0 :: any
	end

	intermediate.dirty = true

	return intermediate
end

local function recomputeValue<T>(intermediate: Intermediate<T>): T
	local value = intermediate.decode(intermediate.components)
	intermediate.value = value
	intermediate.dirty = nil
	return value
end

local function getValue<T>(intermediate: Intermediate<T>): T
	return if intermediate.dirty then recomputeValue(intermediate) else intermediate.value
end

local function setValue<T>(intermediate: Intermediate<T>, value: T): boolean
	local currentValue = getValue(intermediate)

	if type(value) == "table" then
		value = merge(currentValue, value)
	end

	if value == currentValue then
		return false
	end

	intermediate.encode(intermediate.components, value)
	intermediate.value = value
	intermediate.dirty = nil

	return true
end

local function addValue<T>(intermediate: Intermediate<T>, value: T)
	local components: Components = {}

	intermediate.encode(components, value)

	for key, component in components do
		intermediate.components[key] += component :: any
	end

	intermediate.dirty = true
end

local function assign<T>(intermediate: Intermediate<T>, source: Intermediate<T>)
	for key, component in source.components do
		intermediate.components[key] = component
	end

	intermediate.value = getValue(source)
	intermediate.dirty = nil
end

local function lerp<T>(intermediate: Intermediate<T>, from: Intermediate<T>, to: Intermediate<T>, alpha: number)
	for key, b in to.components do
		local a = from.components[key] :: any
		intermediate.components[key] = a + (b - a) * alpha
	end

	intermediate.dirty = true
end

return {
	create = create,
	copy = copy,
	zero = zero,
	setValue = setValue,
	addValue = addValue,
	getValue = getValue,
	recomputeValue = recomputeValue,
	assign = assign,
	lerp = lerp,
}
