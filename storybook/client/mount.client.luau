-- Temporarily mount the storybook to the PlayerGui until UI Labs supports
-- require-by-string semantics.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage["@rbxts-js"].React)
local ReactRoblox = require(ReplicatedStorage["@rbxts-js"].ReactRoblox)
local story = require(ReplicatedStorage.storybook.stories["SpringCFrame.story"])

local root = ReactRoblox.createRoot(Instance.new("Folder"))

root:render(ReactRoblox.createPortal({
	story = React.createElement("ScreenGui", { ResetOnSpawn = false }, {
		React.createElement(story.story),
	}),
}, Players.LocalPlayer.PlayerGui, "storybook"))
