local React = require(script.Parent.Parent.React)
local Ripple = require(script.Parent.Parent.Ripple)

type Binding<T> = React.Binding<T>
type Animatable = Ripple.Animatable
type Tween<T> = Ripple.Tween<T>
type TweenOptions<T> = Ripple.TweenOptions<T>

local function useTween<T>(initialValue: T, initialOptions: TweenOptions<T>?): (Binding<T>, Tween<T>)
	local value, setValue = React.useBinding(initialValue)
	local tween = React.useRef((nil :: any) :: Tween<T>)

	if not tween.current then
		tween.current = Ripple.createTween(initialValue, initialOptions)
	end

	React.useEffect(function()
		if not (initialOptions and initialOptions.start == false) then
			tween.current:start()
		end

		local disconnect = tween.current:onChange(setValue)

		return function()
			disconnect()
			tween.current:stop()
			tween.current = nil :: never
		end
	end, {})

	return value, tween.current
end

return useTween
