local merge = require("./merge")
local oklab = require("./oklab")

export type Components = { number | vector }

export type Intermediate<T = any> = {
	kind: string,
	components: Components,
	value: T,
	dirty: boolean,
}

local function valueToComponents(value: any, kind: string): Components
	if kind == "number" or kind == "vector" or kind == "Vector3" then
		return { value }
	elseif kind == "table" then
		return table.clone(value)
	elseif kind == "Vector2" then
		return { vector.create(value.X, value.Y, 0) }
	elseif kind == "CFrame" then
		return { value.Position, value:ToAxisAngle() }
	elseif kind == "Color3" then
		return { oklab.fromSRGB(value) }
	elseif kind == "UDim" then
		return { vector.create(value.Scale, value.Offset, 0) }
	elseif kind == "UDim2" then
		return { vector.create(value.X.Scale, value.X.Offset, value.Y.Scale), value.Y.Offset }
	elseif kind == "Rect" then
		return { vector.create(value.Min.X, value.Min.Y, value.Max.X), value.Max.Y }
	else
		error(`Attempt to animate unsupported type (got {kind})`)
	end
end

local function componentsToValue(components: { any }, kind: string): any
	if kind == "number" or kind == "vector" or kind == "Vector3" then
		return components[1]
	elseif kind == "table" then
		return table.clone(components)
	elseif kind == "Vector2" then
		local xy: vector = components[1]
		return Vector2.new(xy.x, xy.y)
	elseif kind == "CFrame" then
		return CFrame.fromAxisAngle(components[2], components[3]) + components[1]
	elseif kind == "Color3" then
		return vector.max(oklab.toSRGB(components[1]), vector.zero)
	elseif kind == "UDim" then
		local so: vector = components[1]
		return UDim.new(so.x, math.round(so.y))
	elseif kind == "UDim2" then
		local xxy: vector = components[1]
		return UDim2.new(xxy.x, math.round(xxy.y), xxy.z, math.round(components[2]))
	elseif kind == "Rect" then
		local xxy: vector = components[1]
		return Rect.new(Vector2.new(xxy.x, xxy.y), Vector2.new(xxy.z, components[2]))
	else
		error(`Attempt to animate unsupported type: {kind}`)
	end
end

local function create<T>(value: T): Intermediate<T>
	local kind = typeof(value)

	return {
		kind = kind,
		components = valueToComponents(value, kind),
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
		intermediate.value = componentsToValue(intermediate.components, intermediate.kind) :: any
		intermediate.dirty = false
	end
	return intermediate.value
end

local function setValue<T>(intermediate: Intermediate<T>, value: T): boolean
	if intermediate.kind == "table" then
		value = merge(getValue(intermediate), value)
	end

	intermediate.dirty = false

	if intermediate.value ~= value then
		intermediate.value = value
		intermediate.components = valueToComponents(value, intermediate.kind)
		return true
	else
		return false
	end
end

local function addValue<T>(intermediate: Intermediate<T>, value: T)
	for key, component in valueToComponents(value, intermediate.kind) do
		intermediate.components[key] += component :: any
	end
	intermediate.dirty = true
end

local function assign<T>(intermediate: Intermediate<T>, source: Intermediate<T>)
	for key, component in source.components do
		intermediate.components[key] = component :: any
	end
	intermediate.value = getValue(source)
	intermediate.dirty = false
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
	zero = zero,
	setValue = setValue,
	addValue = addValue,
	getValue = getValue,
	assign = assign,
	lerp = lerp,
}
