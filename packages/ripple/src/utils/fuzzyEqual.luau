local function fuzzyEqual<T>(a: T, b: T, epsilon: number): boolean
	if type(a) == "number" then
		return math.abs(a - b) <= epsilon
	elseif type(a) == "vector" then
		local abs = vector.abs(a - b)
		return abs.x <= epsilon and abs.y <= epsilon and abs.z <= epsilon
	else
		return a == b
	end
end

return fuzzyEqual
