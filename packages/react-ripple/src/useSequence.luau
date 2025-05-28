local React = require(script.Parent.Parent.React)
local Ripple = require(script.Parent.Parent.Ripple)

type Binding<T> = React.Binding<T>
type Animatable = Ripple.Animatable
type Sequence<T> = Ripple.Sequence<T>
type SequenceKeypoint<T> = Ripple.SequenceKeypoint<T>

local function useSequence<T>(
	initialValue: T,
	keypoints: { SequenceKeypoint<T> },
	startImmediately: boolean?
): (Binding<T>, Sequence<T>)
	local value, setValue = React.useBinding(initialValue)
	local sequenceRef = React.useRef((nil :: any) :: Sequence<T>)

	if not sequenceRef.current then
		sequenceRef.current = Ripple.createSequence(initialValue, keypoints)
	end

	React.useEffect(function()
		local disconnect = sequenceRef.current:onChange(setValue)

		if startImmediately ~= false then
			sequenceRef.current:start()
		end

		return function()
			sequenceRef.current:stop()
			disconnect()
		end
	end, {})

	return value, sequenceRef.current
end

return useSequence
