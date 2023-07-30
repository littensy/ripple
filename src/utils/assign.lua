local function assign<T>(object: T, ...: { [any]: any }): T
	assert(type(object) == "table", `Expected a table for first argument, got ${type(object)}`)

	for index = 1, select("#", ...) do
		local source = select(index, ...)

		for key, value in source do
			object[key] = value
		end
	end

	return object
end

return assign
