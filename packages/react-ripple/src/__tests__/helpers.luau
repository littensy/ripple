local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ReactGlobals = require(ReplicatedStorage["@rbxts-js"].ReactGlobals)

ReactGlobals.__ROACT_17_MOCK_SCHEDULER__ = true

local ReactRoblox = require(ReplicatedStorage["@rbxts-js"].ReactRoblox)

local mountedContainers = {}

local function render(element: any)
	local container = Instance.new("Folder")
	local root = ReactRoblox.createLegacyRoot(container)

	mountedContainers[container] = root

	ReactRoblox.act(function()
		root:render(element)
	end)

	return {
		unmount = function()
			ReactRoblox.act(function()
				root:unmount()
			end)
		end,
	}
end

local function cleanup()
	for _, root in mountedContainers do
		ReactRoblox.act(function()
			root:unmount()
		end)
	end
	table.clear(mountedContainers)
end

return {
	render = render,
	cleanup = cleanup,
}
