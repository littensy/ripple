local TweenService = game and game:GetService("TweenService")

local function getValue(alpha: number, easing: Enum.EasingStyle?, direction: Enum.EasingDirection?): number
	if not TweenService then
		return alpha
	end

	return TweenService:GetValue(alpha, easing or Enum.EasingStyle.Linear, direction or Enum.EasingDirection.Out)
end

local function ease(
	progress: number,
	easing: Enum.EasingStyle?,
	direction: Enum.EasingDirection?,
	repeats: number,
	reverses: boolean
): number
	local alpha = progress

	if repeats > 1 and progress >= 1 then
		if reverses then
			return getValue(math.abs((progress - 1) % 2 - 1), easing, direction)
		elseif progress < repeats then
			return getValue(progress % 1, easing, direction)
		else
			return 1
		end
	else
		return getValue(alpha, easing, direction)
	end
end

return ease
