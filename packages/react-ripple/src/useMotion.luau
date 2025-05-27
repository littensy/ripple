local React = require(script.Parent.Parent.React)
local Ripple = require(script.Parent.Parent.Ripple)

type Binding<T> = React.Binding<T>
type Animatable = Ripple.Animatable
type Motion<T> = Ripple.Motion<T>
type MotionConfig<T> = Ripple.MotionConfig<T>

local function useMotion<T>(initialValue: T, initialConfig: MotionConfig<T>?): (Binding<T>, Motion<T>)
	local value, setValue = React.useBinding(initialValue)
	local motionRef = React.useRef((nil :: any) :: Motion<T>)

	if not motionRef.current then
		motionRef.current = Ripple.createMotion(initialValue, initialConfig)
	end

	React.useEffect(function()
		local disconnect = motionRef.current.onChange(setValue)
		if not initialConfig or initialConfig.start ~= false then
			motionRef.current.start()
		end
		return function()
			motionRef.current.stop()
			disconnect()
		end
	end, {})

	return value, motionRef.current
end

return useMotion
