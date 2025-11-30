local Ripple = require(script.Parent.Parent.Ripple)
local Vide = require(script.Parent.Parent.Vide)

type Animatable = Ripple.Animatable
type Spring<T> = Ripple.Spring<T>
type SpringOptions<T> = Ripple.SpringOptions<T>

local function useSpring<T>(initialValue: T, initialOptions: SpringOptions<T>?): (() -> T, Spring<T>)
	local spring = Ripple.createSpring(initialValue, initialOptions)
	local getter = Vide.source(initialValue)

	if not initialOptions or initialOptions.start ~= false then
		spring:start()
	end

	Vide.cleanup(spring:onChange(getter))
	Vide.cleanup(spring)

	return getter, spring
end

return useSpring
