local Ripple = require(script.Parent.Parent.Ripple)
local Vide = require(script.Parent.Parent.Vide)

type Animatable = Ripple.Animatable
type Tween<T> = Ripple.Tween<T>
type TweenOptions<T> = Ripple.TweenOptions<T>

local function useTween<T>(initialValue: T, initialOptions: TweenOptions<T>?): (() -> T, Tween<T>)
	local tween = Ripple.createTween(initialValue, initialOptions)
	local getter = Vide.source(initialValue)

	if not initialOptions or initialOptions.start ~= false then
		tween:start()
	end

	Vide.cleanup(tween:onChange(getter))
	Vide.cleanup(tween)

	return getter, tween
end

return useTween
