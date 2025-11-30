--[[
	https://bottosson.github.io/posts/oklab/

	Copyright (c) 2020 Björn Ottosson
	Permission is hereby granted, free of charge, to any person obtaining a copy of
	this software and associated documentation files (the "Software"), to deal in
	the Software without restriction, including without limitation the rights to
	use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
	of the Software, and to permit persons to whom the Software is furnished to do
	so, subject to the following conditions:
	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.
	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.
]]

local function f(x: number): number
	return if x >= 0.0031308 then 1.055 * x ^ (1.0 / 2.4) - 0.055 else 12.92 * x
end

local function fInv(x: number): number
	return if x >= 0.04045 then ((x + 0.055) / (1 + 0.055)) ^ 2.4 else x / 12.92
end

local function cbrt(x: number): number
	return if x >= 0 then x ^ (1 / 3) else -(-x) ^ (1 / 3)
end

local function fromSRGB(srgb: vector): vector
	-- convert sRGB to linear RGB
	local rgb = vector.create(fInv(srgb.x), fInv(srgb.y), fInv(srgb.z))

	local lmsRoot = vector.create(
		cbrt(vector.dot(vector.create(0.4122214708, 0.5363325363, 0.0514459929), rgb)),
		cbrt(vector.dot(vector.create(0.2119034982, 0.6806995451, 0.1073969566), rgb)),
		cbrt(vector.dot(vector.create(0.0883024619, 0.2817188376, 0.6299787005), rgb))
	)

	return vector.create(
		vector.dot(vector.create(0.2104542553, 0.7936177850, -0.0040720468), lmsRoot),
		vector.dot(vector.create(1.9779984951, -2.4285922050, 0.4505937099), lmsRoot),
		vector.dot(vector.create(0.0259040371, 0.7827717662, -0.8086757660), lmsRoot)
	)
end

local function toSRGB(lab: vector): vector
	local lmsRoot = vector.create(
		vector.dot(vector.create(1, 0.3963377774, 0.2158037573), lab),
		vector.dot(vector.create(1, -0.1055613458, -0.0638541728), lab),
		vector.dot(vector.create(1, -0.0894841775, -1.2914855480), lab)
	)

	local lms = lmsRoot * lmsRoot * lmsRoot

	local rgb = vector.create(
		vector.dot(vector.create(4.0767416621, -3.3077115913, 0.2309699292), lms),
		vector.dot(vector.create(-1.2684380046, 2.6097574011, -0.3413193965), lms),
		vector.dot(vector.create(-0.0041960863, -0.7034186147, 1.7076147010), lms)
	)

	-- convert linear RGB to sRGB
	return vector.create(f(rgb.x), f(rgb.y), f(rgb.z))
end

return {
	fromSRGB = fromSRGB,
	toSRGB = toSRGB,
}
