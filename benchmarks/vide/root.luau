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

--# selene: allow(unused_variable)
--# selene: allow(incorrect_standard_library_use)
--# selene: allow(multiple_statements)
--# selene: allow(mismatched_arg_count)

local graph = require("./graph")
type Node<T> = graph.Node<T>
local create_node = graph.create_node
local push_scope = graph.push_scope
local pop_scope = graph.pop_scope
local destroy = graph.destroy

local refs = {}

local function root<T...>(fn: (destroy: () -> ()) -> T...): (() -> (), T...)
	local node = create_node(false, false, false)

	refs[node] = true -- prevent gc of root node

	local destroy = function()
		if not refs[node] then
			error("root already destroyed")
		end
		refs[node] = nil
		destroy(node)
	end

	push_scope(node)

	local result = { xpcall(fn, debug.traceback, destroy) }

	pop_scope()

	if not result[1] then
		destroy()
		error(`error while running root():\n\n{result[2]}`, 0)
	end

	return destroy, unpack(result :: any, 2)
end

return root :: <T...>(fn: (destroy: () -> ()) -> T...) -> (() -> (), T...)
