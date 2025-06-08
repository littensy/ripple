local oklab = require("./oklab")
local types = require("../types")

type Animatable = types.Animatable

local function interpolate(from: any, to: any, alpha: number): Animatable
	local kind = typeof(from)

	if kind == "number" or kind == "vector" or kind == "Vector3" or kind == "Vector2" then
		return from + (to - from) * alpha
	elseif kind == "Color3" then
		local a = oklab.fromSRGB(vector.create(from.R, from.G, from.B))
		local b = oklab.fromSRGB(vector.create(to.R, to.G, to.B))
		return oklab.toSRGB(a + (b - a) * alpha)
	elseif kind == "UDim2" or kind == "CFrame" then
		return from:Lerp(to, alpha)
	elseif kind == "UDim" then
		return UDim.new(from.Scale + (to.Scale - from.Scale) * alpha, from.Offset + (to.Offset - from.Offset) * alpha)
	elseif kind == "Rect" then
		return Rect.new(
			from.Min.X + (to.Min.X - from.Min.X) * alpha,
			from.Min.Y + (to.Min.Y - from.Min.Y) * alpha,
			from.Max.X + (to.Max.X - from.Max.X) * alpha,
			from.Max.Y + (to.Max.Y - from.Max.Y) * alpha
		)
	elseif kind == "table" then
		local result: { number | vector } = from

		for key, b in to do
			local a = from[key]
			if not a then
				continue
			end

			local value = a + (b - a) * alpha
			if result[key] == value then
				continue
			elseif result == from then
				result = table.clone(from)
			end

			result[key] = value
		end

		return result
	else
		error(`Unsupported type for interpolation: {kind}`)
	end
end

return interpolate
