local React = require(script.Parent.Parent.React)
local Ripple = require(script.Parent.Parent.Ripple)

type Binding<T> = React.Binding<T>
type Animatable = Ripple.Animatable
type Spring<T> = Ripple.Spring<T>
type SpringConfig<T> = Ripple.SpringConfig<T>

local function useSpring<T>(initialValue: T, initialConfig: SpringConfig<T>?): (Binding<T>, Spring<T>)
	local value, setValue = React.useBinding(initialValue)
	local springRef = React.useRef((nil :: any) :: Spring<T>)

	if not springRef.current then
		springRef.current = Ripple.createSpring(initialValue, initialConfig)
	end

	React.useEffect(function()
		local disconnect = springRef.current.onChange(setValue)
		if not initialConfig or initialConfig.start ~= false then
			springRef.current.start()
		end
		return function()
			springRef.current.stop()
			disconnect()
		end
	end, {})

	return value, springRef.current
end

return useSpring
