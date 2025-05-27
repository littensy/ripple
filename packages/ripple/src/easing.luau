export type Easing =
	| "linear"
	| "sineIn"
	| "sineOut"
	| "sineInOut"
	| "backIn"
	| "backOut"
	| "backInOut"
	| "quadIn"
	| "quadOut"
	| "quadInOut"
	| "quartIn"
	| "quartOut"
	| "quartInOut"
	| "quintIn"
	| "quintOut"
	| "quintInOut"
	| "bounceIn"
	| "bounceOut"
	| "bounceInOut"
	| "elasticIn"
	| "elasticOut"
	| "elasticInOut"
	| "expoIn"
	| "expoOut"
	| "expoInOut"
	| "circIn"
	| "circOut"
	| "circInOut"
	| "cubicIn"
	| "cubicOut"
	| "cubicInOut"
	| "smoothstep"
	| "instant"

--[[
	Easing functions borrowed from easings.net:
	https://github.com/ai/easings.net/blob/master/src/easings/easingsFunctions.ts
]]

local pow = math.pow
local sqrt = math.sqrt
local sin = math.sin
local cos = math.cos
local PI = math.pi
local c1 = 1.70158
local c2 = c1 * 1.525
local c3 = c1 + 1
local c4 = (2 * PI) / 3
local c5 = (2 * PI) / 4.5

local function bounceOut(x: number): number
	local n1 = 7.5625
	local d1 = 2.75

	if x < 1 / d1 then
		return n1 * x * x
	elseif x < 2 / d1 then
		x -= 1.5 / d1
		return n1 * x * x + 0.75
	elseif x < 2.5 / d1 then
		x -= 2.25 / d1
		return n1 * x * x + 0.9375
	else
		x -= 2.625 / d1
		return n1 * x * x + 0.984375
	end
end

local easing = {
	linear = function(x: number): number
		return x
	end,
	quadIn = function(x: number): number
		return x * x
	end,
	quadOut = function(x: number): number
		return 1 - (1 - x) * (1 - x)
	end,
	quadInOut = function(x: number): number
		return if x < 0.5 then 2 * x * x else 1 - pow(-2 * x + 2, 2) / 2
	end,
	cubicIn = function(x: number): number
		return x * x * x
	end,
	cubicOut = function(x: number): number
		return 1 - pow(1 - x, 3)
	end,
	cubicInOut = function(x: number): number
		return if x < 0.5 then 4 * x * x * x else 1 - pow(-2 * x + 2, 3) / 2
	end,
	quartIn = function(x: number): number
		return x * x * x * x
	end,
	quartOut = function(x: number): number
		return 1 - pow(1 - x, 4)
	end,
	quartInOut = function(x: number): number
		return if x < 0.5 then 8 * x * x * x * x else 1 - pow(-2 * x + 2, 4) / 2
	end,
	quintIn = function(x: number): number
		return x * x * x * x * x
	end,
	quintOut = function(x: number): number
		return 1 - pow(1 - x, 5)
	end,
	quintInOut = function(x: number): number
		return if x < 0.5 then 16 * x * x * x * x * x else 1 - pow(-2 * x + 2, 5) / 2
	end,
	sineIn = function(x: number): number
		return 1 - cos((x * PI) / 2)
	end,
	sineOut = function(x: number): number
		return sin((x * PI) / 2)
	end,
	sineInOut = function(x: number): number
		return -(cos(PI * x) - 1) / 2
	end,
	expoIn = function(x: number): number
		return if x == 0 then 0 else pow(2, 10 * x - 10)
	end,
	expoOut = function(x: number): number
		return if x == 1 then 1 else 1 - pow(2, -10 * x)
	end,
	expoInOut = function(x: number): number
		return if x == 0
			then 0
			elseif x == 1 then 1
			elseif x < 0.5 then pow(2, 20 * x - 10) / 2
			else (2 - pow(2, -20 * x + 10)) / 2
	end,
	circIn = function(x: number): number
		return 1 - sqrt(1 - pow(x, 2))
	end,
	circOut = function(x: number): number
		return sqrt(1 - pow(x - 1, 2))
	end,
	circInOut = function(x: number): number
		return if x < 0.5 then (1 - sqrt(1 - pow(2 * x, 2))) / 2 else (sqrt(1 - pow(-2 * x + 2, 2)) + 1) / 2
	end,
	backIn = function(x: number): number
		return c3 * x * x * x - c1 * x * x
	end,
	backOut = function(x: number): number
		return 1 + c3 * pow(x - 1, 3) + c1 * pow(x - 1, 2)
	end,
	backInOut = function(x: number): number
		return if x < 0.5
			then (pow(2 * x, 2) * ((c2 + 1) * 2 * x - c2)) / 2
			else (pow(2 * x - 2, 2) * ((c2 + 1) * (x * 2 - 2) + c2) + 2) / 2
	end,
	elasticIn = function(x: number): number
		return if x == 0 then 0 elseif x == 1 then 1 else -pow(2, 10 * x - 10) * sin((x * 10 - 10.75) * c4)
	end,
	elasticOut = function(x: number): number
		return if x == 0 then 0 elseif x == 1 then 1 else pow(2, -10 * x) * sin((x * 10 - 0.75) * c4) + 1
	end,
	elasticInOut = function(x: number): number
		return if x == 0
			then 0
			elseif x == 1 then 1
			elseif x < 0.5 then -(pow(2, 20 * x - 10) * sin((20 * x - 11.125) * c5)) / 2
			else (pow(2, -20 * x + 10) * sin((20 * x - 11.125) * c5)) / 2 + 1
	end,
	bounceIn = function(x: number): number
		return 1 - bounceOut(1 - x)
	end,
	bounceOut = bounceOut,
	bounceInOut = function(x: number): number
		return if x < 0.5 then (1 - bounceOut(1 - 2 * x)) / 2 else (1 + bounceOut(2 * x - 1)) / 2
	end,
	smoothstep = function(x: number): number
		return x * x * (3 - 2 * x)
	end,
	instant = function(x: number): number
		return if x == 0 then 0 else 1
	end,
}

return easing
