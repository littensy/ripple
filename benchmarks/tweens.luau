local bench = require("./bench")
local createTween = require("../packages/ripple/src/animation/createTween")
local heartbeat = require("../packages/ripple/src/heartbeat")

local FPS = 60
local TWEENS = 100

local config = { start = true, duration = 2, easing = "quartOut" :: "quartOut" }

bench("ripple", function()
	local tweens = table.create(TWEENS)

	for index = 1, TWEENS do
		local tween = createTween(0, config)
		tween.to(1)
		tweens[index] = tween
	end

	for _ = 1, FPS do
		heartbeat.step(1 / FPS)
		for _, tween in tweens do
			local _ = tween.position
		end
	end

	heartbeat.clear()
end)
