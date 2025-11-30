local Ripple = require(script.Parent.Parent.Ripple)
local Vide = require(script.Parent.Parent.Vide)

type Animatable = Ripple.Animatable
type Motion<T> = Ripple.Motion<T>
type MotionOptions<T> = Ripple.MotionOptions<T>

local function useMotion<T>(initialValue: T, initialOptions: MotionOptions<T>?): (() -> T, Motion<T>)
	local motion = Ripple.createMotion(initialValue, initialOptions)
	local getter = Vide.source(initialValue)

	if not initialOptions or initialOptions.start ~= false then
		motion:start()
	end

	Vide.cleanup(motion:onChange(getter))
	Vide.cleanup(motion)

	return getter, motion
end

return useMotion
