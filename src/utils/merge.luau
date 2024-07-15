local function merge<T, U>(a: T & { [any]: any }, b: U & { [any]: any }): T & U
	local copy = table.clone(a)

	for key, value in pairs(b) do
		copy[key] = value
	end

	return copy :: never
end

return merge
