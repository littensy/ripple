--[[
	Copyright (c) 2023 Roblox Corporation

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

local assign = require("./assign")
local createSignal = require("./createSignal")

local AnimationStepSignal = require("./AnimationStepSignal")

local types = require("./types")
type AnimationValue = types.AnimationValue
type Goal<T> = types.Goal<T>
type State = types.State
type Motor<T, U> = types.Motor<T, U>

type Unsubscribe = types.Unsubscribe
type MotorCallback<T> = types.MotorCallback<T>

type ValueGroup = {
	[string]: AnimationValue,
}
type GoalGroup = {
	[string]: Goal<any>,
}

type GroupMotorInternal = {
	__goals: GoalGroup,
	__states: {
		[string]: State,
	},
	__allComplete: boolean,
	__onComplete: createSignal.Signal<ValueGroup>,
	__fireOnComplete: createSignal.FireSignal<ValueGroup>,
	__onStep: createSignal.Signal<ValueGroup>,
	__fireOnStep: createSignal.FireSignal<ValueGroup>,
	__running: boolean,
	__connection: RBXScriptConnection?,

	start: (self: GroupMotorInternal) -> (),
	stop: (self: GroupMotorInternal) -> (),
	step: (self: GroupMotorInternal, dt: number) -> (),
	setGoal: (self: GroupMotorInternal, goal: GoalGroup) -> (),
	onStep: (self: GroupMotorInternal, callback: MotorCallback<ValueGroup>) -> Unsubscribe,
	onComplete: (self: GroupMotorInternal, callback: MotorCallback<ValueGroup>) -> Unsubscribe,
	destroy: (self: GroupMotorInternal) -> (),
}

local GroupMotor = {} :: GroupMotorInternal
(GroupMotor :: any).__index = GroupMotor

export type GroupMotor = Motor<GoalGroup, ValueGroup>

local function createGroupMotor(initialValues: ValueGroup): GroupMotor
	local states = {}

	for key, value in pairs(initialValues) do
		states[key] = {
			value = value,
			complete = true,
		}
	end

	local onComplete, fireOnComplete = createSignal()
	local onStep, fireOnStep = createSignal()

	local self = {
		__goals = {},
		__states = states,
		__allComplete = true,
		__onComplete = onComplete,
		__fireOnComplete = fireOnComplete,
		__onStep = onStep,
		__fireOnStep = fireOnStep,
		__running = false,
	}

	setmetatable(self, GroupMotor)

	return self :: any
end

function GroupMotor:start()
	if self.__running then
		return
	end

	self.__connection = AnimationStepSignal:Connect(function(dt)
		self:step(dt)
	end)

	self.__running = true
end

function GroupMotor:stop()
	if self.__connection ~= nil then
		self.__connection:Disconnect()
		self.__running = false
	end
end

function GroupMotor:step(dt: number)
	if self.__allComplete then
		return
	end

	local allComplete = true
	local values = {}

	for key, state in pairs(self.__states) do
		if not state.complete then
			local goal = self.__goals[key]

			if goal ~= nil then
				local maybeNewState = goal.step(state, dt)

				if maybeNewState ~= nil then
					state = maybeNewState
					self.__states[key] = maybeNewState
				end
			else
				state.complete = true
			end

			if not state.complete then
				allComplete = false
			end
		end

		values[key] = state.value
	end

	local wasAllComplete = self.__allComplete
	self.__allComplete = allComplete

	self.__fireOnStep(values)

	-- Check self.__allComplete as the motor may have been restarted in the onStep callback
	-- even if allComplete is true.
	-- Check self.__running in case the motor was stopped by onStep
	if self.__allComplete and not wasAllComplete and self.__running then
		self:stop()
		self.__fireOnComplete(values)
	end
end

function GroupMotor:setGoal(goals: GoalGroup)
	self.__goals = assign({}, self.__goals, goals)

	for key in pairs(goals) do
		local state = self.__states[key]

		if state == nil then
			error(("Cannot set goal for the value %s because it doesn't exist"):format(tostring(key)), 2)
		end

		state.complete = false
	end

	self.__allComplete = false
	self:start()
end

function GroupMotor:onStep(callback: MotorCallback<ValueGroup>)
	local subscription = self.__onStep:subscribe(callback)

	return function()
		subscription:unsubscribe()
	end
end

function GroupMotor:onComplete(callback: MotorCallback<ValueGroup>)
	local subscription = self.__onComplete:subscribe(callback)

	return function()
		subscription:unsubscribe()
	end
end

function GroupMotor:destroy()
	self:stop()
end

return createGroupMotor
