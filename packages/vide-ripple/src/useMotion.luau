local Ripple = require(script.Parent.Parent.Ripple)
local Vide = require(script.Parent.Parent.Vide)
local callable = require(script.Parent.callable)

type Animatable = Ripple.Animatable
type Motion<T> = Ripple.Motion<T>
type MotionOptions<T> = Ripple.MotionOptions<T>

export type VideMotion<T> = (() -> T) & Motion<T> & {
	source: () -> T,
}

local function useMotion<T>(initialValue: T, initialOptions: MotionOptions<T>?): VideMotion<T>
	local motion = Ripple.createMotion(initialValue, initialOptions) :: VideMotion<T>

	motion.source = Vide.source(initialValue)

	if not initialOptions or initialOptions.start ~= false then
		motion:start()
	end

	Vide.cleanup(motion:onChange(motion.source))
	Vide.cleanup(motion)

	return callable(motion, function()
		return motion.source()
	end)
end

return useMotion
