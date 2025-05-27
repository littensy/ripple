local Ripple = require(script.Parent.Parent.Ripple)
local Vide = require(script.Parent.Parent.Vide)
local callable = require(script.Parent.callable)

type Animatable = Ripple.Animatable
type Motion<T> = Ripple.Motion<T>
type MotionConfig<T> = Ripple.MotionConfig<T>

export type VideMotion<T> = (() -> T) & Motion<T> & {
	source: () -> T,
}

local function useMotion<T>(initialValue: T, initialConfig: MotionConfig<T>?): VideMotion<T>
	local motion = Ripple.createMotion(initialValue, initialConfig) :: VideMotion<T>

	motion.source = Vide.source(initialValue)

	if not initialConfig or initialConfig.start ~= false then
		motion.start()
	end

	Vide.cleanup(motion.onChange(motion.source))
	Vide.cleanup(motion.stop)

	return callable(motion, function()
		return motion.source()
	end)
end

return useMotion
