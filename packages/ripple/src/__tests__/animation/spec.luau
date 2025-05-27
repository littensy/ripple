local suite = require("../../../../../test/suite")

suite.describe("createMotion", function()
	require("./createMotion.spec")
end)

suite.describe("createSequence", function()
	require("./createSequence.spec")
end)

suite.describe("createSpring", function()
	require("./createSpring.spec")
end)

suite.describe("createTween", function()
	require("./createTween.spec")
end)

return {}
