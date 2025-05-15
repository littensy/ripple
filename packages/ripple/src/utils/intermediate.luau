local merge = require("./merge")

export type Components = { vector | number }

export type Intermediate<T = any> = {
	kind: string,
	components: Components,
	value: T,
	dirty: boolean,
}

local valueToComponents = {
	number = function(value: number): Components
		return { value }
	end,

	table = function(value: Components): Components
		return table.clone(value)
	end,

	vector = function(value: vector): Components
		return { value }
	end,

	Vector2 = function(value: Vector2): Components
		return { vector.create(value.X, value.Y, 0) }
	end,

	Vector3 = function(value: Vector3): Components
		return { value } :: { any }
	end,

	CFrame = function(value: CFrame): Components
		return { value.Position, value:ToAxisAngle() } :: { any }
	end,

	Color3 = function(value: Color3): Components
		return { vector.create(value.R, value.G, value.B) }
	end,

	UDim = function(value: UDim): Components
		return { vector.create(value.Scale, value.Offset, 0) }
	end,

	UDim2 = function(value: UDim2): Components
		return { vector.create(value.X.Scale, value.X.Offset, value.Y.Scale), value.Y.Offset }
	end,

	Rect = function(value: Rect): Components
		return { vector.create(value.Min.X, value.Min.Y, value.Max.X), value.Max.Y }
	end,
}

local componentsToValue = {
	number = function(components: { number }): number
		return components[1]
	end,

	table = function(components: { number | vector }): Components
		return table.clone(components)
	end,

	vector = function(components: { vector }): vector
		return components[1]
	end,

	Vector2 = function(components: { vector }): Vector2
		local vector = components[1]
		return Vector2.new(vector.x, vector.y)
	end,

	Vector3 = function(components: { Vector3 }): Vector3
		return components[1]
	end,

	CFrame = function(components: { number | Vector3 }): CFrame
		local position = components[1] :: Vector3
		local axis = components[2] :: Vector3
		local angle = components[3] :: number
		return CFrame.fromAxisAngle(axis, angle) + position
	end,

	Color3 = function(components: { vector }): Color3
		local value = vector.max(vector.zero, components[1])
		return Color3.new(value.x, value.y, value.z)
	end,

	UDim = function(components: { vector }): UDim
		local vector = components[1]
		return UDim.new(vector.x, math.round(vector.y))
	end,

	UDim2 = function(components: { number | Vector3 }): UDim2
		local vector = components[1] :: Vector3
		local number = components[2] :: number
		return UDim2.new(vector.X, math.round(vector.Y), vector.Z, math.round(number))
	end,

	Rect = function(components: { number | Vector3 }): Rect
		local vector = components[1] :: Vector3
		local number = components[2] :: number
		return Rect.new(Vector2.new(vector.X, vector.Y), Vector2.new(vector.Z, number))
	end,
}

local function toComponents(value: any, kind: string): Components
	local converter = valueToComponents[kind]

	if not converter then
		error(`Attempt to animate unsupported type (got {kind})`)
	end

	return converter(value)
end

local function fromComponents(components: Components, kind: string): any
	local converter = componentsToValue[kind]

	if not converter then
		error(`Attempt to animate unsupported type (got {kind})`)
	end

	return converter(components)
end

local function create<T>(value: T): Intermediate<T>
	local kind = typeof(value)

	return {
		kind = kind,
		components = toComponents(value, kind),
		value = value,
		dirty = false,
	}
end

local function zero<T>(intermediate: Intermediate<T>): Intermediate<T>
	for key in intermediate.components do
		intermediate.components[key] *= 0 :: any
	end

	intermediate.dirty = true

	return intermediate
end

local function getValue<T>(intermediate: Intermediate<T>): T
	if intermediate.dirty then
		intermediate.value = fromComponents(intermediate.components, intermediate.kind) :: any
		intermediate.dirty = false
	end
	return intermediate.value
end

local function setValue<T>(intermediate: Intermediate<T>, value: T)
	if intermediate.kind == "table" then
		value = merge(getValue(intermediate), value)
	end
	if intermediate.value ~= value then
		intermediate.value = value
		intermediate.components = toComponents(value, intermediate.kind)
	end
	intermediate.dirty = false
end

local function addValue<T>(intermediate: Intermediate<T>, value: T)
	local components = toComponents(value, intermediate.kind)

	for key, component in components do
		intermediate.components[key] += component :: any
	end

	intermediate.dirty = true

	return intermediate
end

local function assign<T>(intermediate: Intermediate<T>, source: Intermediate<T>)
	intermediate.value = getValue(source)
	intermediate.components = source.components
	intermediate.dirty = false
end

local function lerp<T>(from: Intermediate<T>, to: Intermediate<T>, alpha: number)
	for key, b in to.components do
		local a = from.components[key] :: any
		from.components[key] = a + (b - a) * alpha
	end
end

return {
	create = create,
	zero = zero,
	setValue = setValue,
	addValue = addValue,
	getValue = getValue,
	assign = assign,
	lerp = lerp,
	fromComponents = fromComponents,
	toComponents = toComponents,
}
