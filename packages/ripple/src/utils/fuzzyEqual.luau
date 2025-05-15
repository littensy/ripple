local function fuzzyEqual(a: number | vector, b: number | vector, epsilon: number): boolean
	local kind = type(a)
	if kind == "number" then
		return math.abs(a :: number - b :: number) <= epsilon
	elseif kind == "vector" then
		local abs = vector.abs(a :: vector - b :: vector)
		return math.max(abs.x, abs.y, abs.z) <= epsilon
	else
		return a == b
	end
end

return fuzzyEqual
