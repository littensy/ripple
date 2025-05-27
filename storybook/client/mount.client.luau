local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage["@rbxts-js"].React)
local ReactRoblox = require(ReplicatedStorage["@rbxts-js"].ReactRoblox)
local easingFunctions = require(ReplicatedStorage.storybook.stories["EasingFunctions.story"])
local springFunctions = require(ReplicatedStorage.storybook.stories["SpringFunctions.story"])

local root = ReactRoblox.createRoot(Instance.new("Folder"))

root:render(ReactRoblox.createPortal({
	easing = React.createElement("ScreenGui", {}, {
		React.createElement(easingFunctions.story),
	}),
	spring = React.createElement("ScreenGui", { Enabled = false }, {
		React.createElement(springFunctions.story),
	}),
}, Players.LocalPlayer.PlayerGui, "storybook"))
