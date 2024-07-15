return function()
	local createMotion = require(script.Parent.Parent.createMotion)
	local snapshot = require(script.Parent.Parent.utils.snapshot)
	local spring = require(script.Parent.spring)

	local snapshots = {
		default = "[0.37,0.73,0.9,0.96,0.98,0.99,0.99,0.99,0.99,1]",
		underdamped = "[0.41,0.84,1.01,1.03,1.02,1.01,0.99,0.99,0.99,1]",
		critical = "[0.36,0.71,0.89,0.95,0.98,0.99,0.99,0.99,0.99,1]",
		overdamped = "[0.31,0.6,0.78,0.87,0.93,0.96,0.97,0.98,0.99,0.99,0.99,0.99,0.99,0.99,0.99,0.99]",
		tension_200 = "[0.43,0.81,0.95,0.99,0.99,1.01,1.01,1]",
		tension_300 = "[0.61,0.98,1.03,1.01,0.99,0.99,1]",
		mass_half = "[0.44,0.74,0.87,0.94,0.97,0.98,0.99,0.99,0.99,0.99,0.99,0.99,1]",
		mass_2 = "[0.27,0.67,0.92,1.03,1.05,1.03,1.02,1.01,0.99,0.99,0.99,0.99,1]",
		friction_20 = "[0.43,0.85,1.01,1.03,1.01,1.01,0.99,0.99,0.99,1]",
		friction_30 = "[0.35,0.67,0.84,0.92,0.96,0.98,0.99,0.99,0.99,0.99,0.99,0.99,1]",
	}

	it("should animate a value", function()
		local motion = snapshot.testSnapshot(spring(1), snapshots.default)
		expect(motion:get()).to.equal(1)
		expect(motion:isComplete()).to.equal(true)
	end)

	it("should accept damping ratio", function()
		local motion

		motion = snapshot.testSnapshot(spring(1, { damping = 0.75 }), snapshots.underdamped)
		expect(motion:isComplete()).to.equal(true)

		motion = snapshot.testSnapshot(spring(1, { damping = 1 }), snapshots.critical)
		expect(motion:isComplete()).to.equal(true)

		motion = snapshot.testSnapshot(spring(1, { damping = 1.3 }), snapshots.overdamped)
		expect(motion:isComplete()).to.equal(false) -- takes longer to settle
	end)

	it("should accept tension", function()
		local motion

		motion = snapshot.testSnapshot(spring(1, { tension = 200 }), snapshots.tension_200)
		expect(motion:isComplete()).to.equal(true)

		motion = snapshot.testSnapshot(spring(1, { tension = 300 }), snapshots.tension_300)
		expect(motion:isComplete()).to.equal(true)
	end)

	it("should accept mass", function()
		local motion

		motion = snapshot.testSnapshot(spring(1, { mass = 0.5 }), snapshots.mass_half)
		expect(motion:isComplete()).to.equal(true)

		motion = snapshot.testSnapshot(spring(1, { mass = 2 }), snapshots.mass_2)
		expect(motion:isComplete()).to.equal(true)
	end)

	it("should accept friction", function()
		local motion

		motion = snapshot.testSnapshot(spring(1, { friction = 20 }), snapshots.friction_20)
		expect(motion:isComplete()).to.equal(true)

		motion = snapshot.testSnapshot(spring(1, { friction = 30 }), snapshots.friction_30)
		expect(motion:isComplete()).to.equal(true)
	end)

	describe("when passed initial values", function()
		it("should accept position", function()
			local motion = createMotion(0)
			motion:to(spring(1, { position = 0.5 }))
			expect(motion:get()).to.equal(0.5)
		end)

		it("should accept velocity", function()
			local motion = createMotion(0)

			motion:to(spring(1, { velocity = 1000 }))
			expect(motion.state[1].velocity).to.equal(1000)

			motion:step(0.1)
			expect(motion:get() > 1).to.equal(true)
		end)

		it("should apply impulse", function()
			local motion = createMotion(0)
			motion:to(spring(1, { impulse = 1 }))
			motion:to(spring(1, { impulse = 1 }))
			expect(motion.state[1].velocity).to.equal(2)
		end)
	end)
end
