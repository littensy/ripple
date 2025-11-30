--[[
	MIT License

	Copyright (c) 2022 centau

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

local graph = require("./graph")
type Node<T> = graph.Node<T>
local create_source_node = graph.create_source_node
local push_child_to_scope = graph.push_child_to_scope
local update_descendants = graph.update_descendants

export type Source<T> = (() -> T) & ((value: T) -> T)

local function source<T>(initial_value: T): Source<T>
	local node = create_source_node(initial_value)

	local function update_source(...): T
		if select("#", ...) == 0 then -- no args were given
			push_child_to_scope(node)
			return node.cache
		end

		local v = ... :: T
		if node.cache == v and (type(v) ~= "table" or table.isfrozen(v)) then
			return v
		end

		node.cache = v
		update_descendants(node)
		return v
	end

	return update_source
end

return source :: (<T>(initial_value: T) -> Source<T>) & (<T>() -> Source<T>)
