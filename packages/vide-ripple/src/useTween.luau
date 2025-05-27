local Ripple = require(script.Parent.Parent.Ripple)
local Vide = require(script.Parent.Parent.Vide)
local callable = require(script.Parent.callable)

type Animatable = Ripple.Animatable
type Tween<T> = Ripple.Tween<T>
type TweenConfig<T> = Ripple.TweenConfig<T>

export type VideTween<T> = (() -> T) & Tween<T> & {
	source: () -> T,
}

local function useTween<T>(initialValue: T, initialConfig: TweenConfig<T>?): VideTween<T>
	local tween = Ripple.createTween(initialValue, initialConfig) :: VideTween<T>

	tween.source = Vide.source(initialValue)

	if not initialConfig or initialConfig.start ~= false then
		tween.start()
	end

	Vide.cleanup(tween.onChange(tween.source))
	Vide.cleanup(tween.stop)

	return callable(tween, function()
		return tween.source()
	end)
end

return useTween
