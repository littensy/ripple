return function()
	local createMotion = require(script.Parent.Parent.createMotion)
	local tween = require(script.Parent.tween)

	-- todo: do not yield in tests

	it("should animate a value", function()
		local motion = createMotion(0)

		motion:to(tween(1, { time = 0.01 }))
		motion:step(0)

		expect(motion:get()).to.equal(0)

		task.wait(0.05)
		motion:step(0)

		expect(motion:get()).to.equal(1)
	end)

	it("should animate multiple values", function()
		local motion = createMotion({ x = 0, y = 0 })

		motion:to(tween({ x = 1, y = 2 }, { time = 0.01 }))
		motion:step(0)

		expect(motion:get()).to.be.ok()
		expect(motion:get().x).to.equal(0)
		expect(motion:get().y).to.equal(0)

		task.wait(0.05)
		motion:step(0)

		expect(motion:get()).to.be.ok()
		expect(motion:get().x).to.equal(1)
		expect(motion:get().y).to.equal(2)

		motion:to({
			x = tween(2, { time = 0.01 }),
			y = tween(3, { time = 0.1 }),
		})

		motion:step(0)

		expect(motion:get()).to.be.ok()
		expect(motion:get().x).to.equal(1)
		expect(motion:get().y).to.equal(2)

		task.wait(0.05)
		motion:step(0)

		expect(motion:get()).to.be.ok()
		expect(motion:get().x).to.equal(2)
		expect(motion:get().y).to.never.equal(3)

		task.wait(0.05)
		motion:step(0)

		expect(motion:get()).to.be.ok()
		expect(motion:get().x).to.equal(2)
		expect(motion:get().y).to.equal(3)
	end)
end
