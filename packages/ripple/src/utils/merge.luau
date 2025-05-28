local function merge<T>(target: any, source: any): T
	local result = target

	for key, value in source do
		if target[key] == value then
			continue
		end

		if result == target then
			result = table.clone(target)
		end

		result[key] = value
	end

	return result
end

return merge
