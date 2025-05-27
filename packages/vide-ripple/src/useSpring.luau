local Ripple = require(script.Parent.Parent.Ripple)
local Vide = require(script.Parent.Parent.Vide)
local callable = require(script.Parent.callable)

type Animatable = Ripple.Animatable
type Spring<T> = Ripple.Spring<T>
type SpringConfig<T> = Ripple.SpringConfig<T>

export type VideSpring<T> = (() -> T) & Spring<T> & {
	source: () -> T,
}

local function useSpring<T>(initialValue: T, initialConfig: SpringConfig<T>?): VideSpring<T>
	local spring = Ripple.createSpring(initialValue, initialConfig) :: VideSpring<T>

	spring.source = Vide.source(initialValue)

	if not initialConfig or initialConfig.start ~= false then
		spring.start()
	end

	Vide.cleanup(spring.onChange(spring.source))
	Vide.cleanup(spring.stop)

	return callable(spring, function()
		return spring.source()
	end)
end

return useSpring
