return function()
	local types = require(script.Parent.types)
	local createMotion = require(script.Parent.createMotion)
	local linear = require(script.Parent.solvers.linear)
	local spy = require(script.Parent.utils.spy)

	it("should return a Motion", function()
		local motion = createMotion(0)
		expect(motion).to.be.ok()
		expect(motion.state).to.be.a("table")
		expect(motion.start).to.be.a("function")
		expect(motion.stop).to.be.a("function")
		expect(motion.get).to.be.a("function")
		expect(motion.set).to.be.a("function")
		expect(motion.getVelocity).to.be.a("function")
		expect(motion.setVelocity).to.be.a("function")
		expect(motion.patch).to.be.a("function")
		expect(motion.impulse).to.be.a("function")
		expect(motion.to).to.be.a("function")
		expect(motion.step).to.be.a("function")
		expect(motion.isComplete).to.be.a("function")
		expect(motion.onComplete).to.be.a("function")
		expect(motion.onStep).to.be.a("function")
		expect(motion.destroy).to.be.a("function")
	end)

	it("should animate a number", function()
		local motion = createMotion(0)

		motion:to(linear(1, { speed = 1 }))
		motion:step(0.5)

		expect(motion:get()).to.equal(0.5)
		expect(motion:isComplete()).to.equal(false)

		motion:step(0.5)

		expect(motion:get()).to.equal(1)
		expect(motion:isComplete()).to.equal(true)
	end)

	it("should animate a vector", function()
		local motion = createMotion(Vector3.new())

		motion:to(linear(Vector3.new(0.5, 0.75, 1), { speed = 1 }))
		motion:step(0.5)

		expect(motion:get()).to.equal(Vector3.new(0.5, 0.5, 0.5))
		expect(motion:isComplete()).to.equal(false)

		motion:step(0.5)

		expect(motion:get()).to.equal(Vector3.new(0.5, 0.75, 1))
		expect(motion:isComplete()).to.equal(true)
	end)

	it("should animate an array", function()
		local motion = createMotion({ 0, 0, 0 })

		motion:to(linear({ 0.5, 0.75, 1 }, { speed = 1 }))
		motion:step(0.5)

		expect(motion:get()[1]).to.equal(0.5)
		expect(motion:get()[2]).to.equal(0.5)
		expect(motion:get()[3]).to.equal(0.5)

		motion:step(0.5)

		expect(motion:get()[1]).to.equal(0.5)
		expect(motion:get()[2]).to.equal(0.75)
		expect(motion:get()[3]).to.equal(1)
	end)

	describe("when calling 'step'", function()
		it("should call onStep", function()
			local motion = createMotion(0)
			local onStep = spy()

			motion:onStep(onStep.handle)
			motion:to(linear(1, { speed = 1 }))
			motion:step(0.5)

			expect(onStep.calls).to.equal(1)
			expect(onStep.arguments[1][1]).to.equal(0.5)
			expect(onStep.arguments[1][2]).to.equal(0.5)

			motion:step(0.5)

			expect(onStep.calls).to.equal(2)
			expect(onStep.arguments[2][1]).to.equal(1)
			expect(onStep.arguments[2][2]).to.equal(0.5)

			motion:step(0.5)

			expect(onStep.calls).to.equal(2)

			motion:to(linear(0, { speed = 1 }))
			motion:step(0.5)

			expect(onStep.calls).to.equal(3)
			expect(onStep.arguments[3][1]).to.equal(0.5)
			expect(onStep.arguments[3][2]).to.equal(0.5)
		end)

		it("should call onComplete", function()
			local motion = createMotion(0)
			local onComplete = spy()

			motion:onComplete(onComplete.handle)
			motion:to(linear(1, { speed = 1 }))
			motion:step(0.5)

			expect(onComplete.calls).to.equal(0)

			motion:step(0.5)

			expect(onComplete.calls).to.equal(1)
			expect(onComplete.arguments[1][1]).to.equal(1)

			motion:step(0.5)

			expect(onComplete.calls).to.equal(1)

			motion:to(linear(0, { speed = 1 }))
			motion:step(1)

			expect(onComplete.calls).to.equal(2)
			expect(onComplete.arguments[2][1]).to.equal(0)
		end)

		it("should not run completed solvers", function()
			local motion = createMotion({ a = 0, b = 0 })
			local dummySpy = spy()
			local immediateSpy = spy()

			motion:to({
				a = dummySpy.handle,
				b = function(key, state, deltaTime)
					immediateSpy.handle(key, state, deltaTime)
					state.value = 1
					state.complete = true
				end,
			})

			expect(motion.state.a.complete).to.equal(false)
			expect(motion.state.b.complete).to.equal(true)
			expect(dummySpy.calls).to.equal(1)
			expect(immediateSpy.calls).to.equal(1)

			motion:step(1)

			expect(motion.state.a.complete).to.equal(false)
			expect(motion.state.b.complete).to.equal(true)
			expect(dummySpy.calls).to.equal(2)
			expect(immediateSpy.calls).to.equal(1)
		end)
	end)

	describe("when calling 'to'", function()
		it("should destroy the old solver", function()
			local motion = createMotion(0)
			local destructor = spy()

			motion:to(function(_, state)
				state.destructor = destructor.handle
			end)

			motion:step(1)
			expect(destructor.calls).to.equal(0)

			motion:to(linear(1))
			expect(destructor.calls).to.equal(1)
		end)

		it("should accept solvers per key", function()
			local motion = createMotion({ a = 0, b = 0 })

			motion:to({
				a = linear(1, { speed = 1 }),
				b = linear(1, { speed = 0.5 }),
			})

			motion:step(0.5)

			expect(motion:get().a).to.equal(0.5)
			expect(motion:get().b).to.equal(0.25)
			expect(motion:isComplete()).to.equal(false)

			motion:step(0.5)

			expect(motion:get().a).to.equal(1)
			expect(motion:get().b).to.equal(0.5)
			expect(motion:isComplete()).to.equal(false)

			motion:step(1)

			expect(motion:get().a).to.equal(1)
			expect(motion:get().b).to.equal(1)
			expect(motion:isComplete()).to.equal(true)
		end)

		it("should mount the solver", function()
			local motion = createMotion(0)
			local step = spy()

			motion:to(step.handle)

			expect(step.calls).to.equal(1)
			expect(step.arguments[1][1]).to.equal(1) -- key
			expect(step.arguments[1][2]).to.be.a("table") -- state
			expect(step.arguments[1][3]).to.equal(0) -- deltaTime
		end)

		it("should accept complex solvers", function()
			local motion = createMotion({ a = 0, b = 0 })

			motion:to(linear({ a = 1 }, { speed = 1 }))
			motion:to(linear({ b = 1 }, { speed = 1 }))
			motion:step(0.5)

			expect(motion:get().a).to.equal(0.5)
			expect(motion:get().b).to.equal(0.5)
			expect(motion:isComplete()).to.equal(false)

			motion:step(0.5)

			expect(motion:get().a).to.equal(1)
			expect(motion:get().b).to.equal(1)
			expect(motion:isComplete()).to.equal(true)
		end)
	end)

	describe("when passing options", function()
		it("should accept heartbeat", function()
			local heartbeat: types.Heartbeat
			local listeners = {}

			local function connect(_self, callback)
				table.insert(listeners, callback)

				local function disconnect()
					table.remove(listeners, table.find(listeners, callback) or -1)
				end

				return { Disconnect = disconnect }
			end

			local function step(deltaTime: number)
				for _, listener in listeners do
					listener(deltaTime)
				end
			end

			heartbeat = {
				Connect = connect,
			}

			local motion = createMotion(0, {
				heartbeat = heartbeat,
				start = true,
			})

			motion:to(linear(1, { speed = 1 }))
			step(0.5)

			expect(motion:get()).to.equal(0.5)
			expect(motion:isComplete()).to.equal(false)

			step(0.5)

			expect(motion:get()).to.equal(1)
			expect(motion:isComplete()).to.equal(true)
		end)
	end)

	describe("patching state", function()
		it("should set a value", function()
			local motion = createMotion({ a = 0, b = 0 })

			motion:to({
				a = linear(1, { speed = 1 }),
				b = linear(1, { speed = 0.5 }),
			})

			motion:step(0.5)

			expect(motion:get().a).to.equal(0.5)
			expect(motion:get().b).to.equal(0.25)

			motion:set({ a = 2 })
			motion:step(0.5)

			expect(motion:get().a).to.equal(1.5)
			expect(motion:get().b).to.equal(0.5)
		end)

		it("should flag as incomplete", function()
			local motion = createMotion({ a = 0, b = 0 })

			motion:to({
				a = linear(1, { speed = 1 }),
				b = linear(1, { speed = 1 }),
			})

			motion:step(1)
			expect(motion:isComplete()).to.equal(true)

			motion:set({ a = 2 })
			expect(motion:isComplete()).to.equal(false)

			motion:step(1)
			expect(motion:isComplete()).to.equal(true)
		end)

		it("should patch the state", function()
			local motion = createMotion({ a = 0, b = 0 })

			motion:patch({
				a = { value = 1 },
			})

			expect(motion:get().a).to.equal(1)
			expect(motion:get().b).to.equal(0)
		end)
	end)
end
