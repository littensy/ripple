local React = require(script.Parent.Parent.React)
local Ripple = require(script.Parent.Parent.Ripple)

type Binding<T> = React.Binding<T>
type Animatable = Ripple.Animatable
type Motion<T> = Ripple.Motion<T>
type MotionOptions<T> = Ripple.MotionOptions<T>

local function useMotion<T>(initialValue: T, initialOptions: MotionOptions<T>?): (Binding<T>, Motion<T>)
	local value, setValue = React.useBinding(initialValue)
	local motion = React.useRef((nil :: any) :: Motion<T>)

	if not motion.current then
		motion.current = Ripple.createMotion(initialValue, initialOptions)
	end

	React.useEffect(function()
		if not (initialOptions and initialOptions.start == false) then
			motion.current:start()
		end

		local disconnect = motion.current:onChange(setValue)

		return function()
			disconnect()
			motion.current:stop()
			motion.current = nil :: never
		end
	end, {})

	return value, motion.current
end

return useMotion
