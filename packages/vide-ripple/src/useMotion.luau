local Ripple = require(script.Parent.Parent.Ripple)
local Vide = require(script.Parent.Parent.Vide)

type Animatable = Ripple.Animatable
type Motion<T> = Ripple.Motion<T>
type MotionOptions<T> = Ripple.MotionOptions<T>

local function useMotion<T>(initialValue: T, initialOptions: MotionOptions<T>?): (() -> T, Motion<T>)
	local motion = Ripple.createMotion(initialValue, initialOptions)
	local value = Vide.source(initialValue)

	if not (initialOptions and initialOptions.start == false) then
		motion:start()
	end

	local disconnect = motion:onChange(value)

	Vide.cleanup(function()
		disconnect()
		motion:stop()
	end)

	return value, motion
end

return useMotion
