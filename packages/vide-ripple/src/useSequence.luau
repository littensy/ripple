local Ripple = require(script.Parent.Parent.Ripple)
local Vide = require(script.Parent.Parent.Vide)
local callable = require(script.Parent.callable)

type Animatable = Ripple.Animatable
type Sequence<T> = Ripple.Sequence<T>
type SequenceKeypoint<T> = Ripple.SequenceKeypoint<T>

export type VideSequence<T> = (() -> T) & Sequence<T> & {
	source: () -> T,
}

local function useSequence<T>(
	initialValue: T,
	keypoints: { SequenceKeypoint<T> },
	startImmediately: boolean?
): VideSequence<T>
	local sequence = Ripple.createSequence(initialValue, keypoints) :: VideSequence<T>

	sequence.source = Vide.source(initialValue)

	if startImmediately ~= false then
		sequence.start()
	end

	Vide.cleanup(sequence.onChange(sequence.source))
	Vide.cleanup(sequence.stop)

	return callable(sequence, function()
		return sequence.source()
	end)
end

return useSequence
