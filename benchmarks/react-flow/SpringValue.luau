--[[
	MIT License

	Copyright (c) 2025 Jack Fox

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

--!nonstrict

local LinearValue = require("./LinearValue")
local Promise = require("./Promise")

local SpringValue = {}
local SpringValues = {}
SpringValue.__index = SpringValue

local EPSILON = 1e-2

function SpringValue.new(initial: LinearValue.LinearValueType, speed: number?, damper: number?)
	local target = LinearValue.fromValue(initial)
	local velocity = {}

	for i = 1, #target._value do
		velocity[i] = 0
	end

	return setmetatable({
		_current = target,
		_goal = target,
		_velocities = velocity,
		_speed = speed or 1,
		_damper = damper or 1,
		_immediate = false,
		_updater = nil,
	}, SpringValue)
end

function SpringValue:Destroy()
	SpringValues[self] = nil
	setmetatable(self, nil)
end

function SpringValue:Impulse(impulse: LinearValue.LinearValueType)
	local impulseValues = LinearValue.fromValue(impulse)._value
	for i = 1, #impulseValues do
		self._velocities[i] = (self._velocities[i] or 0) + impulseValues[i]
	end
end

function SpringValue:GetVelocity()
	return LinearValue.new(self._current._ccstr, unpack(self._velocities)):ToValue()
end

function SpringValue:SetGoal(goal: LinearValue.LinearValueType)
	self._goal = LinearValue.fromValue(goal)
end

function SpringValue:SetSpeed(speed: number)
	self._speed = speed
end

function SpringValue:SetDamper(damper: number)
	self._damper = damper
end

function SpringValue:SetImmediate(immediate: boolean)
	self._immediate = immediate
end

function SpringValue:SetUpdater(updater: (any) -> ())
	self._updater = updater

	if self:Playing() and updater then
		updater(self:GetValue())
	end
end

function SpringValue:GetGoal()
	return self._goal:ToValue()
end

function SpringValue:SetValue(value: LinearValue.LinearValueType)
	self._current = LinearValue.fromValue(value)
end

function SpringValue:GetValue()
	return self._current:ToValue()
end

function SpringValue:Update(dt: number)
	local currentValues = self._current._value
	local goalValues = self._goal._value
	local velocities = self._velocities

	local newValues = {}
	local updated = false

	for i = 1, #currentValues do
		local goalValue = goalValues[i]
		local baseValue, baseVelocity = currentValues[i], velocities[i] or 0
		local position, newVelocity = self:getPositionVelocity(dt, baseValue, baseVelocity, goalValue)

		newValues[i] = position
		velocities[i] = newVelocity

		if math.abs(position - goalValue) > EPSILON or math.abs(newVelocity) > EPSILON then
			updated = true
		end
	end

	self._current = LinearValue.new(self._current._ccstr, unpack(newValues))

	return updated
end

function SpringValue:Playing()
	return SpringValues[self] ~= nil
end

function SpringValue:Stop()
	local value = SpringValues[self]
	if value then
		SpringValues[self] = nil
		value()
	end
end

function SpringValue:Run(update: () -> ()?)
	if update then
		self._updater = update
	end

	if self._immediate then
		self._current = self._goal

		if self._updater then
			self._updater(self:GetValue())
		end

		return Promise.resolve()
	end

	return Promise.new(function(resolve, _, onCancel)
		onCancel(function()
			self:Stop()
		end)

		if update then
			update(self:GetValue())
		end

		SpringValues[self] = resolve
	end)
end

-- credit to @Quenty
-- https://github.com/Quenty/NevermoreEngine/blob/main/src/spring/src/Shared/Spring.lua
function SpringValue:getPositionVelocity(dt: number, current: number, velocity: number, target: number)
	local p0 = current
	local v0 = velocity
	local p1 = target
	local d = self._damper
	local s = self._speed

	local t = s * dt
	local d2 = d * d

	local h, si, co
	if d2 < 1 then
		h = math.sqrt(1 - d2)
		local ep = math.exp(-d * t) / h
		co, si = ep * math.cos(h * t), ep * math.sin(h * t)
	elseif d2 == 1 then
		h = 1
		local ep = math.exp(-d * t) / h
		co, si = ep, ep * t
	else
		h = math.sqrt(d2 - 1)
		local u = math.exp((-d + h) * t) / (2 * h)
		local v = math.exp((-d - h) * t) / (2 * h)
		co, si = u + v, u - v
	end

	local a0 = h * co + d * si
	local a1 = 1 - (h * co + d * si)
	local a2 = si / s

	local b0 = -s * si
	local b1 = s * si
	local b2 = h * co - d * si

	return a0 * p0 + a1 * p1 + a2 * v0, b0 * p0 + b1 * p1 + b2 * v0
end

function SpringValue.step(dt: number)
	for spring, resolve in pairs(SpringValues) do
		local didUpdate = spring:Update(dt)
		local value = spring:GetValue()

		if spring._updater then
			spring._updater(value)
		end

		if not didUpdate then
			SpringValues[spring] = nil
			resolve()
		end
	end
end

function SpringValue.clear()
	table.clear(SpringValues)
end

return SpringValue
