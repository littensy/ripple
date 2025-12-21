local React = require(script.Parent.Parent.React)
local Ripple = require(script.Parent.Parent.Ripple)

type Binding<T> = React.Binding<T>
type Animatable = Ripple.Animatable
type Spring<T> = Ripple.Spring<T>
type SpringOptions<T> = Ripple.SpringOptions<T>

local function useSpring<T>(initialValue: T, initialOptions: SpringOptions<T>?): (Binding<T>, Spring<T>)
	local value, setValue = React.useBinding(initialValue)
	local spring = React.useRef((nil :: any) :: Spring<T>)

	if not spring.current then
		spring.current = Ripple.createSpring(initialValue, initialOptions)
	end

	React.useEffect(function()
		if not (initialOptions and initialOptions.start == false) then
			spring.current:start()
		end

		local disconnect = spring.current:onChange(setValue)

		return function()
			disconnect()
			spring.current:stop()
			spring.current = nil :: never
		end
	end, {})

	return value, spring.current
end

return useSpring
