--[[
	Copyright (c) 2018-2023 Roblox Corporation

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.
]]

--!strict
export type MotorCallback<T> = (T) -> ()
export type Unsubscribe = () -> ()

-- Animation values need to be continuous and interpolatable; for now, that's
-- probably just numbers, but one could imagine something more sophisticated
export type AnimationValue = number

type Empty = {}
export type State = {
	value: AnimationValue,
	complete: boolean,
}

export type Goal<T = Empty> = {
	step: (state: State & T, dt: number) -> State & T,
}

export type Motor<T, U> = {
	start: (self: Motor<T, U>) -> (),
	stop: (self: Motor<T, U>) -> (),
	step: (self: Motor<T, U>, dt: number) -> (),
	setGoal: (self: Motor<T, U>, goal: T) -> (),
	onStep: (self: Motor<T, U>, callback: MotorCallback<U>) -> Unsubscribe,
	onComplete: (self: Motor<T, U>, callback: MotorCallback<U>) -> Unsubscribe,
	destroy: (self: Motor<T, U>) -> (),
}

return {}
