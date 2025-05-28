local Ripple = require(script.Parent.Parent.Ripple)
local Vide = require(script.Parent.Parent.Vide)

type Animatable = Ripple.Animatable
type Sequence<T> = Ripple.Sequence<T>
type SequenceKeypoint<T> = Ripple.SequenceKeypoint<T>

local function useSequence<T>(
	initialValue: T,
	keypoints: { SequenceKeypoint<T> },
	startImmediately: boolean?
): (() -> T, Sequence<T>)
	local sequence = Ripple.createSequence(initialValue, keypoints)
	local getter = Vide.source(initialValue)

	if startImmediately ~= false then
		sequence:start()
	end

	Vide.cleanup(sequence:onChange(getter))
	Vide.cleanup(sequence)

	return getter, sequence
end

return useSequence
