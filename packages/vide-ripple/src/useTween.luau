local Ripple = require(script.Parent.Parent.Ripple)
local Vide = require(script.Parent.Parent.Vide)

type Animatable = Ripple.Animatable
type Tween<T> = Ripple.Tween<T>
type TweenOptions<T> = Ripple.TweenOptions<T>

local function useTween<T>(initialValue: T, initialOptions: TweenOptions<T>?): (() -> T, Tween<T>)
	local tween = Ripple.createTween(initialValue, initialOptions)
	local value = Vide.source(initialValue)

	if not (initialOptions and initialOptions.start == false) then
		tween:start()
	end

	local disconnect = tween:onChange(value)

	Vide.cleanup(function()
		disconnect()
		tween:stop()
	end)

	return value, tween
end

return useTween
