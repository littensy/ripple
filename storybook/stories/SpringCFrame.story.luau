local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage["@rbxts-js"].React)
local ReactRipple = require(ReplicatedStorage.packages["react-ripple"].src)
local ReactRoblox = require(ReplicatedStorage["@rbxts-js"].ReactRoblox)

return {
	name = "Spring CFrame",
	story = function()
		local cameraBinding, setCamera = React.useBinding(nil :: Camera?)
		local cframeBinding, cframeSpring = ReactRipple.useSpring(CFrame.identity, ReactRipple.config.wobbly)

		React.useEffect(function()
			local angle = 0
			local thread = task.spawn(function()
				while true do
					angle += math.pi / 4
					cframeSpring:setGoal(CFrame.fromEulerAnglesXYZ(angle, 0, 0))
					task.wait(1)
				end
			end)
			return function()
				task.cancel(thread)
			end
		end, {})

		return React.createElement("ViewportFrame", {
			CurrentCamera = cameraBinding,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
		}, {
			Camera = React.createElement("Camera", {
				ref = setCamera,
				CFrame = CFrame.lookAt(Vector3.new(0, 0, 4), Vector3.zero),
			}),
			Part = React.createElement("Part", {
				Size = Vector3.new(1, 1, 1),
				Anchored = true,
				CFrame = cframeBinding,
			}),
		})
	end,
	react = React,
	reactRoblox = ReactRoblox,
}
