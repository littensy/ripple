local function callable<Object, Args..., Results...>(object: Object, callback: (Args...) -> Results...): Object & (Args...) -> Results...
	return setmetatable(object :: any, {
		__call = function(_, ...)
			return callback(...)
		end,
	})
end

return callable
