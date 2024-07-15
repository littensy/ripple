type Intermediate = { [any]: number }

local intermediates = {
	number = {
		to = function(value: number): Intermediate
			return { value }
		end,
		from = function(value: Intermediate): number
			return value[1]
		end,
	},

	table = {
		to = function(value: Intermediate): Intermediate
			return value
		end,
		from = function(value: Intermediate): Intermediate
			return value
		end,
	},

	UDim2 = {
		to = function(value: UDim2): Intermediate
			return { value.X.Scale, value.X.Offset, value.Y.Scale, value.Y.Offset }
		end,
		from = function(value: Intermediate): UDim2
			return UDim2.new(value[1], math.round(value[2]), value[3], math.round(value[4]))
		end,
	},

	UDim = {
		to = function(value: UDim): Intermediate
			return { value.Scale, value.Offset }
		end,
		from = function(value: Intermediate)
			return UDim.new(value[1], math.round(value[2]))
		end,
	},

	Vector2 = {
		to = function(value: Vector2): Intermediate
			return { value.X, value.Y }
		end,
		from = function(value: Intermediate): Vector2
			return Vector2.new(table.unpack(value, 1, 2))
		end,
	},

	Vector3 = {
		to = function(value: Vector3): Intermediate
			return { value.X, value.Y, value.Z }
		end,
		from = function(value: Intermediate): Vector3
			return Vector3.new(table.unpack(value, 1, 3))
		end,
	},

	Color3 = {
		to = function(value: Color3): Intermediate
			return { value.R, value.G, value.B }
		end,
		from = function(value: Intermediate): Color3
			return Color3.new(math.clamp(value[1], 0, 1), math.clamp(value[2], 0, 1), math.clamp(value[3], 0, 1))
		end,
	},

	CFrame = {
		to = function(value: CFrame): Intermediate
			return { value:GetComponents() }
		end,
		from = function(value: Intermediate): CFrame
			return CFrame.new(table.unpack(value))
		end,
	},
}

local function to(value: unknown): Intermediate
	local type = typeof(value)

	if intermediates[type] then
		return intermediates[type].to(value)
	else
		error(`Ripple received an unsupported value '{value}' of type '{type}'`)
	end
end

local function from<T>(value: Intermediate, type: string): T
	if intermediates[type] then
		return intermediates[type].from(value)
	else
		error(`Ripple received an unsupported value '{value}' of type '{type}'`)
	end
end

local function index(value: Intermediate, key: unknown): number?
	return value[key] or value[1]
end

return {
	to = to,
	from = from,
	index = index,
}
