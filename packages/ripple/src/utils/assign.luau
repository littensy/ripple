local function assign<T>(target: T, ...: { [any]: any }): T
	local result = target :: any

	for index = 1, select("#", ...) do
		local source: { [any]: any } = select(index, ...)

		for key, value in source do
			result[key] = value
		end
	end

	return result
end

return assign
