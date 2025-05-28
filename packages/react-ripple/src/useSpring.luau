local React = require(script.Parent.Parent.React)
local Ripple = require(script.Parent.Parent.Ripple)

type Binding<T> = React.Binding<T>
type Animatable = Ripple.Animatable
type Spring<T> = Ripple.Spring<T>
type SpringOptions<T> = Ripple.SpringOptions<T>

local function useSpring<T>(initialValue: T, initialOptions: SpringOptions<T>?): (Binding<T>, Spring<T>)
	local value, setValue = React.useBinding(initialValue)
	local springRef = React.useRef((nil :: any) :: Spring<T>)

	if not springRef.current then
		springRef.current = Ripple.createSpring(initialValue, initialOptions)
	end

	React.useEffect(function()
		local disconnect = springRef.current:onChange(setValue)

		if not initialOptions or initialOptions.start ~= false then
			springRef.current:start()
		end

		return function()
			springRef.current:stop()
			disconnect()
		end
	end, {})

	return value, springRef.current
end

return useSpring
