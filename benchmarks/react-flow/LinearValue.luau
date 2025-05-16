--!nonstrict

local LinearValue = {}

export type LinearValueType =
	number
	| UDim2
	| UDim
	| Vector2
	| Vector3
	| Color3
	| ColorSequenceKeypoint
	| NumberSequenceKeypoint
	| Rect
	| NumberRange
	| PhysicalProperties
	| BrickColor
	| CFrame
	| Ray
	| Region3
	| Region3int16

function LinearValue.fromValue(value: any)
	local typeString = typeof(value)

	if typeString == "number" then
		return LinearValue.new(nil, value)
	elseif typeString == "UDim2" then
		return LinearValue.new(UDim2.new, value.X.Scale, value.X.Offset, value.Y.Scale, value.Y.Offset)
	elseif typeString == "UDim" then
		return LinearValue.new(UDim.new, value.Scale, value.Offset)
	elseif typeString == "Vector2" then
		return LinearValue.new(Vector2.new, value.X, value.Y)
	elseif typeString == "Vector3" then
		return LinearValue.new(Vector3.new, value.X, value.Y, value.Z)
	elseif typeString == "Color3" then
		return LinearValue.new(Color3.new, value.R, value.G, value.B)
	elseif typeString == "ColorSequenceKeypoint" then
		return LinearValue.new(ColorSequenceKeypoint.new, value.Time, value.Value)
	elseif typeString == "NumberSequenceKeypoint" then
		return LinearValue.new(NumberSequenceKeypoint.new, value.Time, value.Value, value.Envelope)
	elseif typeString == "NumberRange" then
		return LinearValue.new(NumberRange.new, value.Min, value.Max)
	elseif typeString == "PhysicalProperties" then
		return LinearValue.new(PhysicalProperties.new, value.Density, value.Friction, value.Elasticity)
	elseif typeString == "BrickColor" then
		return LinearValue.new(Color3.new, value.Color.R, value.Color.G, value.Color.B)
	elseif typeString == "CFrame" then
		local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = value:components()
		return LinearValue.new(CFrame.new, x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22)
	end

	assert(false, "Unsupported type: " .. typeString)
end

function LinearValue.new(constructor, ...)
	return table.freeze({
		_ccstr = constructor,
		_value = { ... },

		ToValue = LinearValue.ToValue,
		Lerp = LinearValue.Lerp,
	})
end

function LinearValue:ToValue()
	if self._ccstr then
		return self._ccstr(unpack(self._value))
	else
		return unpack(self._value)
	end
end

function LinearValue:Lerp(other, alpha)
	local newValues = {}

	for i = 1, #self._value do
		newValues[i] = self._value[i] + (other._value[i] - self._value[i]) * alpha
	end

	return LinearValue.new(self._ccstr, unpack(newValues))
end

return LinearValue
