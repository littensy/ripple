--[[
	MIT License

	Copyright (c) Roblox

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

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

--!strict

-- Marker used to specify that the value is nothing, because nil cannot be
-- stored in tables.
local None = newproxy(true)
local mt = getmetatable(None)
mt.__tostring = function()
	return "Object.None"
end

--[[
	Merges values from zero or more tables onto a target table. If a value is
	set to None, it will instead be removed from the table.

	This function is identical in functionality to JavaScript's Object.assign.
]]
-- Luau TODO: no way to strongly type this accurately, it doesn't eliminate deleted keys of T, and Luau won't do intersections of type packs: <T, ...U>(T, ...: ...U): T & ...U
return function<T, U, V, W>(target: T, source0: U?, source1: V?, source2: W?, ...): T & U & V & W
	if source0 ~= nil and typeof(source0 :: any) == "table" then
		for key, value in pairs(source0 :: any) do
			if value == None then
				(target :: any)[key] = nil
			else
				(target :: any)[key] = value
			end
		end
	end

	if source1 ~= nil and typeof(source1 :: any) == "table" then
		for key, value in pairs(source1 :: any) do
			if value == None then
				(target :: any)[key] = nil
			else
				(target :: any)[key] = value
			end
		end
	end

	if source2 ~= nil and typeof(source2 :: any) == "table" then
		for key, value in pairs(source2 :: any) do
			if value == None then
				(target :: any)[key] = nil
			else
				(target :: any)[key] = value
			end
		end
	end

	for index = 1, select("#", ...) do
		local rest = select(index, ...)

		if rest ~= nil and typeof(rest) == "table" then
			for key, value in pairs(rest) do
				if value == None then
					(target :: any)[key] = nil
				else
					(target :: any)[key] = value
				end
			end
		end
	end

	-- TODO? we can add & Object to this, if needed by real-world code, once CLI-49825 is fixed
	return (target :: any) :: T & U & V & W
end
