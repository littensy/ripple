local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage["@rbxts-js"].React)
local ReactRipple = require(ReplicatedStorage.packages["react-ripple"].src)
local ReactRoblox = require(ReplicatedStorage["@rbxts-js"].ReactRoblox)

local function Story()
	local _, tween = ReactRipple.useTween(Color3.new(), { start = false })

	local keypoints = React.useMemo(function()
		local keypoints = {}
		local points = 16

		tween:setPosition(Color3.new(1, 1, 1))
		tween:setGoal(Color3.new(0, 0, 1))

		for point = 0, points do
			local color = tween:getPosition()
			local colorClamped =
				Color3.new(math.clamp(color.R, 0, 1), math.clamp(color.G, 0, 1), math.clamp(color.B, 0, 1))
			table.insert(keypoints, ColorSequenceKeypoint.new(point / points, colorClamped))
			tween:step(1 / points)
		end

		return keypoints
	end, {})

	return React.createElement("Frame", {
		BackgroundColor3 = Color3.new(1, 1, 1),
		Size = UDim2.new(1, 0, 1, 0),
	}, {
		React.createElement("UIGradient", {
			Color = ColorSequence.new(keypoints),
		}),
	})
end

return function(container: Instance)
	local root = ReactRoblox.createRoot(container)

	root:render(React.createElement(Story))

	return function()
		root:unmount()
	end
end
