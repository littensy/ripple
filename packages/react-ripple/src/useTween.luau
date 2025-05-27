local React = require(script.Parent.Parent.React)
local Ripple = require(script.Parent.Parent.Ripple)

type Binding<T> = React.Binding<T>
type Animatable = Ripple.Animatable
type Tween<T> = Ripple.Tween<T>
type TweenConfig<T> = Ripple.TweenConfig<T>

local function useTween<T>(initialValue: T, initialConfig: TweenConfig<T>?): (Binding<T>, Tween<T>)
	local value, setValue = React.useBinding(initialValue)
	local tweenRef = React.useRef((nil :: any) :: Tween<T>)

	if not tweenRef.current then
		tweenRef.current = Ripple.createTween(initialValue, initialConfig)
	end

	React.useEffect(function()
		local disconnect = tweenRef.current.onChange(setValue)
		if not initialConfig or initialConfig.start ~= false then
			tweenRef.current.start()
		end
		return function()
			tweenRef.current.stop()
			disconnect()
		end
	end, {})

	return value, tweenRef.current
end

return useTween
