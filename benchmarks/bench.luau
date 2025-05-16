local function bench(name: string, test: () -> ())
	local start = os.clock()
	local iter = 500
	for _ = 1, iter do
		test()
	end
	local elapsed = os.clock() - start
	print(`{name}: {string.format("%.2f", elapsed / iter * 1000 * 1000)} us/iter`)
end

return bench
