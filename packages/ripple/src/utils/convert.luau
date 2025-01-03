--!native
--!optimize 2

export type Components = {
	[any]: Vector3 | number,
}

export type Animatable = number | vector | Components | Vector2 | Vector3 | CFrame | Color3 | UDim | UDim2 | Rect

local valueToComponents = {
	number = function(value: number): Components
		return { value }
	end,

	table = function(value: Components): Components
		return table.clone(value)
	end,

	Vector2 = function(value: Vector2): Components
		return { Vector3.new(value.X, value.Y) }
	end,

	Vector3 = function(value: Vector3): Components
		return { value }
	end,

	CFrame = function(value: CFrame): Components
		return { value.Position, value:ToAxisAngle() }
	end,

	Color3 = function(value: Color3): Components
		return { Vector3.new(value.R, value.G, value.B) }
	end,

	UDim = function(value: UDim): Components
		return { Vector3.new(value.Scale, value.Offset) }
	end,

	UDim2 = function(value: UDim2): Components
		return { Vector3.new(value.X.Scale, value.X.Offset, value.Y.Scale), value.Y.Offset }
	end,

	Rect = function(value: Rect): Components
		return { Vector3.new(value.Min.X, value.Min.Y, value.Max.X), value.Max.Y }
	end,
}

local componentsToValue = {
	number = function(components: { number }): number
		return components[1]
	end,

	table = function(components: { number | Vector3 }): Components
		return table.clone(components)
	end,

	Vector2 = function(components: { Vector3 }): Vector2
		local vector = components[1]
		return Vector2.new(vector.X, vector.Y)
	end,

	Vector3 = function(components: { Vector3 }): Vector3
		return components[1]
	end,

	CFrame = function(components: { any }): CFrame
		local position: Vector3 = components[1]
		local axis: Vector3 = components[2]
		local angle: number = components[3]
		return CFrame.fromAxisAngle(axis, angle) + position
	end,

	Color3 = function(components: { Vector3 }): Color3
		local vector = components[1]:Min(Vector3.one):Max(Vector3.zero)
		return Color3.new(vector.X, vector.Y, vector.Z)
	end,

	UDim = function(components: { Vector3 }): UDim
		local vector = components[1]
		return UDim.new(vector.X, math.round(vector.Y))
	end,

	UDim2 = function(components: { any }): UDim2
		local vector: Vector3 = components[1]
		local number: number = components[2]
		return UDim2.new(vector.X, math.round(vector.Y), vector.Z, math.round(number))
	end,

	Rect = function(components: { any }): Rect
		local vector: Vector3 = components[1]
		local number: number = components[2]
		return Rect.new(Vector2.new(vector.X, vector.Y), Vector2.new(vector.Z, number))
	end,
}

local function toComponents(value: Animatable, kind: string): Components
	local converter = valueToComponents[kind]

	if not converter then
		error(`Attempt to animate unsupported type (got {kind})`)
	end

	return converter(value)
end

local function fromComponents(components: Components, kind: string): Animatable
	local converter = componentsToValue[kind]

	if not converter then
		error(`Attempt to animate unsupported type (got {kind})`)
	end

	return converter(components)
end

local function toZeros(components: Components): Components
	local zero = table.clone(components)

	for index, component in zero do
		zero[index] = type(component) == "number" and 0 or Vector3.zero
	end

	return zero
end

return {
	toComponents = toComponents,
	fromComponents = fromComponents,
	toZeros = toZeros,
}
