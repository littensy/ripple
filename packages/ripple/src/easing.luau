export type Easing =
	| "linear"
	| "instant"
	| "smoothstep"
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

-- Easing functions borrowed from easings.net:
-- https://github.com/ai/easings.net/blob/master/src/easings/easingsFunctions.ts

local PI = math.pi
local c1 = 1.70158
local c2 = c1 * 1.525
local c3 = c1 + 1
local c4 = (2 * PI) / 3
local c5 = (2 * PI) / 4.5

local function linear(x: number): number
	return x
end

local function instant(x: number): number
	return if x == 0 then 0 else 1
end

local function smoothstep(x: number): number
	return x * x * (3 - 2 * x)
end

local function quadIn(x: number): number
	return x * x
end

local function quadOut(x: number): number
	return 1 - (1 - x) * (1 - x)
end

local function quadInOut(x: number): number
	return if x < 0.5 then 2 * x * x else 1 - ((-2 * x + 2) ^ 2) / 2
end

local function cubicIn(x: number): number
	return x * x * x
end

local function cubicOut(x: number): number
	return 1 - (1 - x) ^ 3
end

local function cubicInOut(x: number): number
	return if x < 0.5 then 4 * x * x * x else 1 - ((-2 * x + 2) ^ 3) / 2
end

local function quartIn(x: number): number
	return x * x * x * x
end

local function quartOut(x: number): number
	return 1 - (1 - x) ^ 4
end

local function quartInOut(x: number): number
	return if x < 0.5 then 8 * x * x * x * x else 1 - ((-2 * x + 2) ^ 4) / 2
end

local function quintIn(x: number): number
	return x * x * x * x * x
end

local function quintOut(x: number): number
	return 1 - (1 - x) ^ 5
end

local function quintInOut(x: number): number
	return if x < 0.5 then 16 * x * x * x * x * x else 1 - ((-2 * x + 2) ^ 5) / 2
end

local function sineIn(x: number): number
	return 1 - math.cos((x * PI) / 2)
end

local function sineOut(x: number): number
	return math.sin((x * PI) / 2)
end

local function sineInOut(x: number): number
	return -(math.cos(PI * x) - 1) / 2
end

local function expoIn(x: number): number
	return if x == 0 then 0 else 2 ^ (10 * x - 10)
end

local function expoOut(x: number): number
	return if x == 1 then 1 else 1 - 2 ^ (-10 * x)
end

local function expoInOut(x: number): number
	return if x == 0
		then 0
		elseif x == 1 then 1
		elseif x < 0.5 then (2 ^ (20 * x - 10)) / 2
		else (2 - (2 ^ (-20 * x + 10))) / 2
end

local function circIn(x: number): number
	return 1 - (1 - (x ^ 2)) ^ 0.5
end

local function circOut(x: number): number
	return (1 - (x - 1) ^ 2) ^ 0.5
end

local function circInOut(x: number): number
	return if x < 0.5 then (1 - (1 - ((2 * x) ^ 2)) ^ 0.5) / 2 else (((1 - ((-2 * x + 2) ^ 2)) ^ 0.5) + 1) / 2
end

local function backIn(x: number): number
	return c3 * x * x * x - c1 * x * x
end

local function backOut(x: number): number
	return 1 + c3 * ((x - 1) ^ 3) + c1 * ((x - 1) ^ 2)
end

local function backInOut(x: number): number
	return if x < 0.5
		then (((2 * x) ^ 2) * ((c2 + 1) * 2 * x - c2)) / 2
		else (((2 * x - 2) ^ 2) * ((c2 + 1) * (x * 2 - 2) + c2) + 2) / 2
end

local function elasticIn(x: number): number
	return if x == 0 then 0 elseif x == 1 then 1 else -(2 ^ (10 * x - 10)) * math.sin((x * 10 - 10.75) * c4)
end

local function elasticOut(x: number): number
	return if x == 0 then 0 elseif x == 1 then 1 else (2 ^ (-10 * x)) * math.sin((x * 10 - 0.75) * c4) + 1
end

local function elasticInOut(x: number): number
	return if x == 0
		then 0
		elseif x == 1 then 1
		elseif x < 0.5 then -((2 ^ (20 * x - 10)) * math.sin((20 * x - 11.125) * c5)) / 2
		else ((2 ^ (-20 * x + 10)) * math.sin((20 * x - 11.125) * c5)) / 2 + 1
end

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

local function bounceIn(x: number): number
	return 1 - bounceOut(1 - x)
end

local function bounceInOut(x: number): number
	return if x < 0.5 then (1 - bounceOut(1 - 2 * x)) / 2 else (1 + bounceOut(2 * x - 1)) / 2
end

return {
	linear = linear,
	instant = instant,
	smoothstep = smoothstep,
	quadIn = quadIn,
	quadOut = quadOut,
	quadInOut = quadInOut,
	cubicIn = cubicIn,
	cubicOut = cubicOut,
	cubicInOut = cubicInOut,
	quartIn = quartIn,
	quartOut = quartOut,
	quartInOut = quartInOut,
	quintIn = quintIn,
	quintOut = quintOut,
	quintInOut = quintInOut,
	sineIn = sineIn,
	sineOut = sineOut,
	sineInOut = sineInOut,
	expoIn = expoIn,
	expoOut = expoOut,
	expoInOut = expoInOut,
	circIn = circIn,
	circOut = circOut,
	circInOut = circInOut,
	backIn = backIn,
	backOut = backOut,
	backInOut = backInOut,
	elasticIn = elasticIn,
	elasticOut = elasticOut,
	elasticInOut = elasticInOut,
	bounceIn = bounceIn,
	bounceOut = bounceOut,
	bounceInOut = bounceInOut,
}
