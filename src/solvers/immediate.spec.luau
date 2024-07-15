return function()
	local createMotion = require(script.Parent.Parent.createMotion)
	local immediate = require(script.Parent.immediate)

	it("should set a value", function()
		local motion = createMotion({ x = 0, y = 0 })

		motion:to(immediate({ x = 1, y = 1 }))
		motion:step(0)

		expect(motion:get()).to.be.ok()
		expect(motion:get().x).to.equal(1)
		expect(motion:get().y).to.equal(1)
		expect(motion:isComplete()).to.equal(true)
	end)

	it("should set multiple values", function()
		local motion = createMotion({ x = 0, y = 0 })

		motion:to({ x = immediate(1), y = immediate(1) })
		motion:step(0)

		expect(motion:get()).to.be.ok()
		expect(motion:get().x).to.equal(1)
		expect(motion:get().y).to.equal(1)
		expect(motion:isComplete()).to.equal(true)

		motion:to({ x = immediate(2), y = immediate(2) })
		motion:step(0)

		expect(motion:get()).to.be.ok()
		expect(motion:get().x).to.equal(2)
		expect(motion:get().y).to.equal(2)
		expect(motion:isComplete()).to.equal(true)
	end)
end
