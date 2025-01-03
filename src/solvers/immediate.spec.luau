return function()
	local createMotion = require(script.Parent.Parent.createMotion)
	local immediate = require(script.Parent.immediate)

	it("should set a value", function()
		local motion = createMotion({ x = 0, y = 0 })

		motion:to(immediate({ x = 1, y = 1 }))
		motion:step(1)

		expect(motion:get()).to.be.ok()
		expect(motion:get().x).to.equal(1)
		expect(motion:get().y).to.equal(1)
		expect(motion:isComplete()).to.equal(true)
	end)

	it("should set multiple values", function()
		local motion = createMotion({ x = 0, y = 0 })

		motion:to({ x = immediate(1), y = immediate(1) })
		motion:step(1)

		expect(motion:get()).to.be.ok()
		expect(motion:get().x).to.equal(1)
		expect(motion:get().y).to.equal(1)
		expect(motion:isComplete()).to.equal(true)

		motion:to({ x = immediate(2), y = immediate(2) })
		motion:step(1)

		expect(motion:get()).to.be.ok()
		expect(motion:get().x).to.equal(2)
		expect(motion:get().y).to.equal(2)
		expect(motion:isComplete()).to.equal(true)
	end)

	it("should wake spring after last completion", function()
		local motion = createMotion(0)

		motion:linear(1, { speed = 1 })
		motion:step(1)

		expect(motion:isComplete()).to.equal(true)

		local firedOnStep = 0
		local firedOnComplete = 0

		motion:onStep(function()
			firedOnStep += 1
		end)

		motion:onComplete(function()
			firedOnComplete += 1
		end)

		motion:immediate(0)
		motion:step(1)

		expect(motion:isComplete()).to.equal(true)
		expect(firedOnStep).to.equal(1)
		expect(firedOnComplete).to.equal(1)

		motion:step(1)

		expect(firedOnStep).to.equal(1)
		expect(firedOnComplete).to.equal(1)
	end)

	it("should trigger events", function()
		local motion = createMotion(0)
		local firedOnStep = 0
		local firedOnComplete = 0

		motion:onStep(function()
			firedOnStep += 1
		end)

		motion:onComplete(function()
			firedOnComplete += 1
		end)

		motion:immediate(0)
		motion:step(1)

		expect(motion:isComplete()).to.equal(true)
		expect(firedOnStep).to.equal(1)
		expect(firedOnComplete).to.equal(1)

		motion:step(1)

		expect(firedOnStep).to.equal(1)
		expect(firedOnComplete).to.equal(1)
	end)
end
