local test = require("./test")

local describeInRoblox = test.describeIf(function()
	return game :: any ~= nil
end)

test.describe("ripple", function()
	require("../packages/ripple/src/__tests__")
end)

describeInRoblox("react-ripple", function()
	require("../packages/react-ripple/src/__tests__")
end)

describeInRoblox("vide-ripple", function()
	require("../packages/vide-ripple/src/__tests__")
end)

test.finish({ verbose = false })

return {}
