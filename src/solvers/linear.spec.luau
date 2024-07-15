return function()
	local createMotion = require(script.Parent.Parent.createMotion)
	local linear = require(script.Parent.linear)

	it("should animate a value", function()
		local motion = createMotion(0)

		motion:to(linear(1, { speed = 1 }))
		motion:step(0.5)

		expect(motion:get()).to.equal(0.5)
		expect(motion:isComplete()).to.equal(false)

		motion:step(0.5)

		expect(motion:get()).to.equal(1)
		expect(motion:isComplete()).to.equal(true)
	end)

	it("should animate multiple values", function()
		local motion = createMotion({ x = 0, y = 0 })

		motion:to(linear({ x = 1, y = 1 }, { speed = 1 }))
		motion:step(0.5)

		expect(motion:get()).to.be.ok()
		expect(motion:get().x).to.equal(0.5)
		expect(motion:get().y).to.equal(0.5)
		expect(motion:isComplete()).to.equal(false)

		motion:step(0.5)

		expect(motion:get()).to.be.ok()
		expect(motion:get().x).to.equal(1)
		expect(motion:get().y).to.equal(1)
		expect(motion:isComplete()).to.equal(true)

		motion:to({
			x = linear(2, { speed = 1 }),
			y = linear(2, { speed = 0.5 }),
		})

		motion:step(0.5)

		expect(motion:get()).to.be.ok()
		expect(motion:get().x).to.equal(1.5)
		expect(motion:get().y).to.equal(1.25)
		expect(motion:isComplete()).to.equal(false)

		motion:step(0.5)

		expect(motion:get()).to.be.ok()
		expect(motion:get().x).to.equal(2)
		expect(motion:get().y).to.equal(1.5)
		expect(motion:isComplete()).to.equal(false)

		motion:step(1)

		expect(motion:get()).to.be.ok()
		expect(motion:get().x).to.equal(2)
		expect(motion:get().y).to.equal(2)
		expect(motion:isComplete()).to.equal(true)
	end)

	it("should complete if overshooting", function()
		local motion = createMotion(0)

		motion:to(linear(1, { speed = 1 }))
		motion:step(1000)

		expect(motion:get()).to.equal(1)
		expect(motion:isComplete()).to.equal(true)
	end)
end
