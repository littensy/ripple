local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Graph = require(script.Parent.Parent.components.Graph)
local React = require(ReplicatedStorage["@rbxts-js"].React)
local ReactRoblox = require(ReplicatedStorage["@rbxts-js"].ReactRoblox)
local Ripple = require(ReplicatedStorage.packages.ripple.src)

type SpringFunctionProps = {
	name: string,
	config: Ripple.SpringConfig,
}

local configs: { [string]: Ripple.SpringConfig } = table.clone(Ripple.config)

configs.empty = {}
configs.figmaGentle = { tension = 100, friction = 15 }
configs.figmaQuick = { tension = 300, friction = 20 }
configs.figmaBouncy = { tension = 600, friction = 15 }
configs.figmaSlow = { tension = 80, friction = 20 }

local function SpringFunction(props: SpringFunctionProps)
	local spring = React.useMemo(function()
		local source = Ripple.createSpring(1, props.config)
		source.goal = 0
		return source
	end, { props.config })

	return React.createElement(Graph, {
		name = props.name,
		precision = 0.001,
		showRuntime = true,
		step = spring.step,
		idle = spring.idle,
	})
end

local function SpringFunctions()
	local children: { [string]: React.ReactNode } = {}

	for name, config in configs do
		children[name] = React.createElement(SpringFunction, {
			name = name,
			config = config,
		})
	end

	return React.createElement("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
	}, {
		GridLayout = React.createElement("UIGridLayout", {
			CellSize = UDim2.new(1 / 3, -8 * 3, 1 / 4, -8 * 4),
			CellPadding = UDim2.fromOffset(8, 8),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			FillDirection = Enum.FillDirection.Horizontal,
		}),
	}, children)
end

return {
	name = "Spring Functions",
	story = SpringFunctions,
	react = React,
	reactRoblox = ReactRoblox,
}
