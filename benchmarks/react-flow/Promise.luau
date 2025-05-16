local Promise = {}

function Promise.new(handler: (resolve: () -> (), reject: () -> (), onCancel: (callback: () -> ()) -> ()) -> ())
	handler(function() end, function() end, function() end)
	return {}
end

function Promise.resolve()
	return {}
end

return Promise
