local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Graph = require(script.Parent.Parent.components.Graph)
local React = require(ReplicatedStorage["@rbxts-js"].React)
local ReactRoblox = require(ReplicatedStorage["@rbxts-js"].ReactRoblox)
local Ripple = require(ReplicatedStorage.packages.ripple.src)

type EasingFunctionProps = {
	easing: Ripple.Easing,
}

local function EasingFunction(props: EasingFunctionProps)
	local tween = React.useMemo(function()
		local source = Ripple.createTween(1, { duration = 1, easing = props.easing })
		source.goal = 0
		return source
	end, { props.easing })

	return React.createElement(Graph, {
		name = props.easing :: string,
		precision = 0.01,
		step = tween.step,
		idle = tween.idle,
	})
end

local function EasingFunctions()
	local children: { [string]: React.ReactNode } = {}

	for name: Ripple.Easing in pairs(Ripple.easing) do
		children[name] = React.createElement(EasingFunction, {
			easing = name,
			duration = 1,
		})
	end

	return React.createElement("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
	}, {
		GridLayout = React.createElement("UIGridLayout", {
			CellSize = UDim2.new(1 / 5, -8 * 5, 1 / 5, -8 * 5),
			CellPadding = UDim2.fromOffset(8, 8),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			FillDirection = Enum.FillDirection.Horizontal,
		}),
	}, children)
end

return {
	name = "Easing Functions",
	story = EasingFunctions,
	react = React,
	reactRoblox = ReactRoblox,
}
