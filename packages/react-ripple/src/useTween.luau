local React = require(script.Parent.Parent.React)
local Ripple = require(script.Parent.Parent.Ripple)

type Binding<T> = React.Binding<T>
type Animatable = Ripple.Animatable
type Tween<T> = Ripple.Tween<T>
type TweenOptions<T> = Ripple.TweenOptions<T>

local function useTween<T>(initialValue: T, initialOptions: TweenOptions<T>?): (Binding<T>, Tween<T>)
	local value, setValue = React.useBinding(initialValue)
	local tweenRef = React.useRef((nil :: any) :: Tween<T>)

	if not tweenRef.current then
		tweenRef.current = Ripple.createTween(initialValue, initialOptions)
	end

	React.useEffect(function()
		local disconnect = tweenRef.current:onChange(setValue)

		if not initialOptions or initialOptions.start ~= false then
			tweenRef.current:start()
		end

		return function()
			tweenRef.current:stop()
			disconnect()
		end
	end, {})

	return value, tweenRef.current
end

return useTween
