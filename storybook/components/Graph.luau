local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.packages.React)

type GraphProps = {
	name: string,
	precision: number,
	step: (dt: number) -> number,
	idle: () -> boolean,
	showRuntime: boolean?,
}

local MAX_POINTS = 50

local function Graph(props: GraphProps)
	local pathRef = React.useRef((nil :: any) :: Path2D)
	local runtime, setRuntime = React.useState(0)

	React.useEffect(function()
		local path = pathRef.current
		local samples: { number } = { props.step(0) }
		local controlPoints: { Path2DControlPoint } = table.create(MAX_POINTS)

		for _ = 1, 2000 do
			table.insert(samples, props.step(props.precision))
			if props.idle() then
				break
			end
		end

		local sampleCount = #samples
		local pointCount = math.min(sampleCount, MAX_POINTS)

		for pointIndex = 0, pointCount - 1 do
			local sampleIndex = math.floor(pointIndex / (pointCount - 1) * (sampleCount - 1))
			local value = samples[sampleIndex + 1]
			local point = Path2DControlPoint.new(UDim2.fromScale(pointIndex / (pointCount - 1), value))
			table.insert(controlPoints, point)
		end

		path:SetControlPoints(controlPoints)

		if props.showRuntime then
			setRuntime(#samples * props.precision)
		end
	end, { props.step })

	return React.createElement("Frame", {
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.4,
	}, {
		Corner = React.createElement("UICorner"),
		Padding = React.createElement("UIPadding", {
			PaddingTop = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 4),
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 8),
		}),
		Text = React.createElement("TextLabel", {
			Text = if runtime > 0 then `{props.name} ({string.format("%.2f", runtime)}s)` else props.name,
			TextSize = 7,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Bottom,
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
		}),
		PathFrame = React.createElement("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, -12),
		}, {
			RulerTop = React.createElement("Frame", {
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 0.8,
				Size = UDim2.new(1, 0, 0, 1),
			}),
			RulerBottom = React.createElement("Frame", {
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 0.8,
				Size = UDim2.new(1, 0, 0, 1),
				Position = UDim2.fromScale(0, 1),
			}),
			Path = React.createElement("Path2D", {
				ref = pathRef,
				Color3 = Color3.fromRGB(180, 180, 180),
				Thickness = 2,
				ZIndex = 2,
			}),
		}),
	})
end

return Graph
